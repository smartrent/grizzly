defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport do
  @moduledoc """
  This command is used to advertise if the firmware update will be initiated.

  Params:

    * `:status` - the status of the firmware update request, either :ok or an error such as :invalid_manufacturer_or_device_id

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type status ::
          :ok
          | :invalid_manufacturer_or_device_id
          | :authenticated_required
          | :excessive_fragment_size
          | :target_not_upgradable
          | :invalid_hardware_version
          | :firmware_update_in_progress
          | :insufficient_battery_level
  @type param :: {:status, status}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :firmware_update_md_request_report,
      command_byte: 0x04,
      command_class: FirmwareUpdateMD,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    status_byte = Command.param!(command, :status) |> encode_status()
    <<status_byte>>
  end

  @impl true
  def decode_params(<<status_byte>>) do
    with {:ok, status} <- decode_status(status_byte) do
      {:ok, [status: status]}
    else
      {:error, error} ->
        error
    end
  end

  def encode_status(:ok), do: 0xFF
  def encode_status(:invalid_manufacturer_or_device_id), do: 0x00
  def encode_status(:authenticated_required), do: 0x01
  def encode_status(:excessive_fragment_size), do: 0x02
  def encode_status(:target_not_upgradable), do: 0x03
  def encode_status(:invalid_hardware_version), do: 0x04
  def encode_status(:firmware_update_in_progress), do: 0x05
  def encode_status(:insufficient_battery_level), do: 0x06

  def decode_status(0xFF), do: {:ok, :ok}
  def decode_status(0x00), do: {:ok, :invalid_manufacturer_or_device_id}
  def decode_status(0x01), do: {:ok, :authenticated_required}
  def decode_status(0x02), do: {:ok, :excessive_fragment_size}
  def decode_status(0x03), do: {:ok, :target_not_upgradable}
  def decode_status(0x04), do: {:ok, :invalid_hardware_version}
  def decode_status(0x05), do: {:ok, :firmware_update_in_progress}
  def decode_status(0x06), do: {:ok, :insufficient_battery_level}

  def decode_status(byte),
    do:
      {:error,
       %DecodeError{value: byte, param: :status, command: :firmware_update_md_request_report}}
end
