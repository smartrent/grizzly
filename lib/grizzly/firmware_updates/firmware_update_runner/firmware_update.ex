defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunner.FirmwareUpdate do
  @moduledoc false

  # This module holds the state of the FirmwareUpdateRunner and
  # knows how to move the process along (which commmand follows which)

  alias Grizzly.FirmwareUpdates
  alias Grizzly.FirmwareUpdates.FirmwareUpdateRunner.Image
  alias Grizzly.ZWave.{Command, CRC}

  alias Grizzly.ZWave.Commands.{
    FirmwareUpdateMDReport,
    FirmwareUpdateMDRequestGet
  }

  require Logger

  @type speed :: {float() | 40 | 100, :kbit_sec}

  @type state :: :started | :updating | :uploading | :complete

  @type t :: %__MODULE__{
          handler: pid() | module() | {module(), keyword},
          conn: pid(),
          image: Image.t() | nil,
          manufacturer_id: non_neg_integer,
          firmware_id: non_neg_integer,
          hardware_version: byte,
          max_fragment_size: non_neg_integer,
          device_id: Grizzly.node_id(),
          firmware_target: byte,
          activation_may_be_delayed?: boolean,
          current_command_ref: reference(),
          state: state,
          # Number of fragments still to be sent as a burst
          fragments_wanted: non_neg_integer,
          # Index of fragment to be sent next. Starts at 1.
          fragment_index: non_neg_integer,
          # Delay between sending fragments. When nil, the default delays allowed
          # by the spec are used. When set, the delay is used for all fragments
          # regardless of transmission speed.
          transmission_delay: nil | non_neg_integer(),
          last_transmission_speed: speed()
        }

  defstruct handler: nil,
            conn: nil,
            # Ref to the currently executing command - so it can be stopped if needed
            current_command_ref: nil,
            device_id: 1,
            image: nil,
            manufacturer_id: nil,
            firmware_id: nil,
            hardware_version: 0,
            firmware_target: 0,
            max_fragment_size: 2048,
            activation_may_be_delayed?: false,
            state: :started,
            fragments_wanted: 0,
            # first frgament has index 1
            fragment_index: 1,
            transmission_delay: nil,
            last_transmission_speed: {40, :kbit_sec}

  @spec put_image(t(), FirmwareUpdates.image_path()) :: t()
  def put_image(firmware_update, image_path) do
    %__MODULE__{firmware_update | image: Image.new(image_path)}
  end

  @spec current_command_ref(t()) :: reference()
  def current_command_ref(firmware_update), do: firmware_update.current_command_ref

  def update_command_ref(firmware_update, new_command_ref),
    do: %__MODULE__{firmware_update | current_command_ref: new_command_ref}

  @spec in_progress?(t()) :: boolean()
  def in_progress?(firmware_update),
    do:
      firmware_update.state not in [:failed, :complete] and
        (firmware_update.fragments_wanted > 0 or firmware_update.fragment_index > 1)

  @doc """
  Store the transmission speed of the last successful command so it can be used
  to calculate the transmission delay.
  """
  @spec put_last_transmission_speed(t(), speed()) :: t()
  def put_last_transmission_speed(firmware_update, {_, :kbit_sec} = speed),
    do: %__MODULE__{firmware_update | last_transmission_speed: speed}

  def put_last_transmission_speed(firmware_update, _), do: firmware_update

  @doc """
  Returns the delay between sending fragments. If set in the `FirmwareUpdate`,
  that value will always be used. Otherwise, the delay is calculated based on
  the last transmission speed: 10ms for 100kbit/s, 35ms for 40kbit/s and 9.6kbit/s.
  """
  @spec transmission_delay(t()) :: pos_integer()
  def transmission_delay(%__MODULE__{transmission_delay: delay})
      when is_integer(delay) and delay > 0,
      do: delay

  def transmission_delay(%__MODULE__{last_transmission_speed: {100, :kbit_sec}}), do: 10
  def transmission_delay(%__MODULE__{last_transmission_speed: {40, :kbit_sec}}), do: 35
  def transmission_delay(%__MODULE__{}), do: 35

  @doc """
  Handle incoming command from the Z-Wave network

  This commands are:

   - `:firmware_update_request_report` - command in response to requesting a firmware update
   - `:firmware_update_md_get` - command to tell Grizzly to send more firmware image fragments
   - `:firmware_md_report` - command sometimes sent during uploading to modify max fragment size
   - `:firmware_update_md_status_report` - the status report about the firmware update process
  """
  @spec handle_command(t(), Command.t()) :: t()
  def handle_command(firmware_update, command) do
    case command.name do
      :firmware_update_md_request_report ->
        update_request_responded(firmware_update, command)

      :firmware_update_md_get ->
        fragments_requested(firmware_update, command)

      :firmware_md_report ->
        max_fragment_size_modified(firmware_update, command)

      :firmware_update_md_status_report ->
        complete(firmware_update, command)

      :firmware_update_activation_report ->
        firmware_activated(firmware_update)

      other ->
        Logger.warning("[Grizzly] Not handling FW update command named #{inspect(other)}")
        firmware_update
    end
  end

  @spec complete?(t()) :: boolean()
  def complete?(%__MODULE__{state: :complete}), do: true
  def complete?(%__MODULE__{}), do: false

  @doc """
  Generate the next command based off the desired state of the firmware update

  This will return the next Z-Wave command to run along with the updated
  firmware update to track the current state of the firmware update process
  """
  @spec next_command(t(), state()) ::
          {Command.t() | nil, t()} | {:error, :updating}
  def next_command(firmware_update, desired_state)

  def next_command(firmware_update, :updating) do
    params = params_for(:firmware_update_md_request_get, firmware_update)
    {:ok, command} = FirmwareUpdateMDRequestGet.new(params)

    {command, firmware_update_requested(firmware_update, params)}
  end

  def next_command(firmware_update, :uploading) do
    {:ok, command} =
      FirmwareUpdateMDReport.new(params_for(:firmware_update_md_update_report, firmware_update))

    last? = Command.param!(command, :last?)
    {command, firmware_fragment_uploaded(firmware_update, last?)}
  end

  @doc "Whether a next command needs to be followed by another to achieve a possibly new desired state"
  @spec continuation(t) :: nil | {:uploading, non_neg_integer}
  def continuation(
        %__MODULE__{state: :uploading, fragments_wanted: fragments_wanted} = firmware_update
      )
      when fragments_wanted > 0 do
    {:uploading, transmission_delay(firmware_update)}
  end

  def continuation(_firmware_update), do: nil

  ### PARAMS FOR THE NEXT COMMANDS

  defp params_for(:firmware_update_md_request_get, firmware_update) do
    [
      manufacturer_id: firmware_update.manufacturer_id,
      firmware_id: firmware_update.firmware_id,
      firmware_target: firmware_update.firmware_target,
      hardware_version: firmware_update.hardware_version,
      fragment_size: firmware_update.max_fragment_size,
      activation_may_be_delayed?: firmware_update.activation_may_be_delayed?,
      checksum: file_checksum(firmware_update.image)
    ]
  end

  defp params_for(:firmware_update_md_update_report, firmware_update) do
    report_number = report_number(firmware_update)
    {last?, data} = data(firmware_update)
    #  Calculate the checksum of the entire command (minus the checksum)

    {:ok, command_without_checksum} =
      FirmwareUpdateMDReport.new(report_number: report_number, last?: last?, data: data)

    params_binary = FirmwareUpdateMDReport.encode_params(command_without_checksum)
    command_binary = <<0x7A, 0x06>> <> params_binary
    checksum = checksum(command_binary)
    [report_number: report_number, data: data, last?: last?, checksum: checksum]
  end

  # STATE TRANSITIONS for commands sent and incoming commands

  defp firmware_update_requested(firmware_update, params) do
    max_fragment_size = Keyword.fetch!(params, :fragment_size)

    image_with_fragments =
      Image.fragment_image(
        firmware_update.image,
        max_fragment_size,
        firmware_update.fragment_index
      )

    %__MODULE__{firmware_update | state: :updating, image: image_with_fragments}
  end

  defp update_request_responded(firmware_update, command) do
    status = Command.param!(command, :status)

    case status do
      :ok -> %__MODULE__{firmware_update | state: :updating}
      _other -> %__MODULE__{firmware_update | state: :complete}
    end
  end

  defp firmware_fragment_uploaded(
         firmware_update,
         true = _last?
       ) do
    %__MODULE__{
      firmware_update
      | fragments_wanted: 0
    }
  end

  defp firmware_fragment_uploaded(
         %__MODULE__{fragments_wanted: fragments_wanted, fragment_index: fragment_index} =
           firmware_update,
         false = _last?
       ) do
    updated_fragments_wanted = fragments_wanted - 1
    updated_fragment_index = fragment_index + 1

    %__MODULE__{
      firmware_update
      | fragments_wanted: updated_fragments_wanted,
        fragment_index: updated_fragment_index
    }
  end

  defp fragments_requested(firmware_update, command) do
    # a number of fragments are requested
    fragments_wanted = Command.param!(command, :number_of_reports)
    # starting from this one (zwave is 1-based so first report number will be 1)
    fragment_index = Command.param!(command, :report_number)

    %__MODULE__{
      firmware_update
      | state: :uploading,
        fragments_wanted: fragments_wanted,
        fragment_index: fragment_index
    }
  end

  defp max_fragment_size_modified(firmware_update, command) do
    max_fragment_size = Command.param!(command, :max_fragment_size)

    image_with_fragments =
      Image.fragment_image(
        firmware_update.image,
        max_fragment_size,
        firmware_update.fragment_index
      )

    %__MODULE__{
      firmware_update
      | max_fragment_size: max_fragment_size,
        image: image_with_fragments
    }
  end

  defp complete(%__MODULE__{state: state} = firmware_update, _command)
       when state not in [:started, :complete] do
    %__MODULE__{firmware_update | state: :complete}
  end

  defp firmware_activated(firmware_update) do
    %__MODULE__{firmware_update | state: :complete}
  end

  ### UTILITY

  defp file_checksum(image) do
    {:ok, bytes} = File.read(image.path)
    checksum(bytes)
  end

  # The checksum algorithm implements a CRC-CCITT using initialization value equal to 0x1D0F and 0x1021
  # (normal representation) as the poly.
  # Results match those of CRC-CCITT (0x1D0F) on https://www.lammertbies.nl/comm/info/crc-calculation
  defp checksum(binary) do
    CRC.crc16_aug_ccitt(binary)
  end

  defp report_number(%__MODULE__{
         fragment_index: fragment_index
       }) do
    fragment_index
  end

  # returns {last?, data}
  defp data(%__MODULE__{
         fragment_index: fragment_index,
         image: image
       }) do
    Image.data(image, fragment_index)
  end
end
