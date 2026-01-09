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

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel
  alias Grizzly.ZWave.DeviceClasses

  @type end_point :: MultiChannel.end_point()
  @type param ::
          {:reports_to_follow, byte}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}
          | {:end_points, [end_point]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    reports_to_follow = Command.param!(command, :reports_to_follow)
    generic_device_class = Command.param!(command, :generic_device_class)
    generic_device_class_byte = encode_generic_class(generic_device_class)

    specific_device_class_byte =
      encode_specific_class(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    end_points = Command.param!(command, :end_points)

    <<reports_to_follow, generic_device_class_byte, specific_device_class_byte>> <>
      encode_end_points(end_points)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(
        <<reports_to_follow, generic_device_class_byte, specific_device_class_byte,
          end_points_binary::binary>>
      ) do
    end_points = decode_end_points(end_points_binary)

    generic_device_class = decode_generic_class(generic_device_class_byte)

    specific_device_class =
      decode_specific_class(generic_device_class, specific_device_class_byte)

    {:ok,
     [
       reports_to_follow: reports_to_follow,
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       end_points: end_points
     ]}
  end

  defp encode_generic_class(:all), do: 0xFF
  defp encode_generic_class(g), do: DeviceClasses.encode_generic(g)

  defp decode_generic_class(0xFF), do: :all
  defp decode_generic_class(g), do: DeviceClasses.decode_generic(g)

  defp encode_specific_class(_g, :all), do: 0xFF
  defp encode_specific_class(g, s), do: DeviceClasses.encode_specific(g, s)

  defp decode_specific_class(_g, 0xFF), do: :all
  defp decode_specific_class(g, s), do: DeviceClasses.decode_specific(g, s)

  defp encode_end_points(end_points) do
    for end_point <- end_points, into: <<>>, do: <<0x00::1, end_point::7>>
  end

  defp decode_end_points(binary) do
    for <<_reserved::1, end_point::7 <- binary>>, do: end_point
  end
end
