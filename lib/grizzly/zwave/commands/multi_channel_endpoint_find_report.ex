defmodule Grizzly.ZWave.Commands.MultiChannelEndpointFindReport do
  @moduledoc """
  This command is used to advertise End Points that implement a given combination of Generic and
  Specific Device Classes.

  Params:

    * `:reports_to_follow` - the number of reports to follow (required)

    * `:generic_device_class` - a generic device class (required)

    * `:specific_device_class` - a specific device class (required)

    * `:end_points` - the list of End Point identifier(s) that matches the advertised Generic and
                      Specific Device Class values. (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, DeviceClasses}
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type end_point :: MultiChannel.end_point()
  @type param ::
          {:reports_to_follow, byte}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}
          | {:end_points, [end_point]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_endpoint_find_report,
      command_byte: 0x0C,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    reports_to_follow = Command.param!(command, :reports_to_follow)
    generic_device_class = Command.param!(command, :generic_device_class)
    generic_device_class_byte = DeviceClasses.generic_device_class_to_byte(generic_device_class)

    specific_device_class_byte =
      DeviceClasses.specific_device_class_to_byte(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    end_points = Command.param!(command, :end_points)

    <<reports_to_follow, generic_device_class_byte, specific_device_class_byte>> <>
      encode_end_points(end_points)
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<reports_to_follow, generic_device_class_byte, specific_device_class_byte,
          end_points_binary::binary>>
      ) do
    end_points = decode_end_points(end_points_binary)

    with {:ok, generic_device_class} <-
           MultiChannel.decode_generic_device_class(generic_device_class_byte),
         {:ok, specific_device_class} <-
           MultiChannel.decode_specific_device_class(
             generic_device_class,
             specific_device_class_byte
           ) do
      {:ok,
       [
         reports_to_follow: reports_to_follow,
         generic_device_class: generic_device_class,
         specific_device_class: specific_device_class,
         end_points: end_points
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_end_points(end_points) do
    for end_point <- end_points, into: <<>>, do: <<0x00::size(1), end_point::size(7)>>
  end

  defp decode_end_points(binary) do
    for <<_reserved::size(1), end_point::size(7) <- binary>>, do: end_point
  end
end
