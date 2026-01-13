defmodule Grizzly.ZWave.Commands.MultiChannelEndpointFind do
  @moduledoc """
  This command is used to request End Points having a specific Generic or Specific Device Class in End
  Points.

  Params:

  * `:generic_device_class` - a generic device class (required)

  * `:specific_device_class` - a specific device class (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DeviceClasses, as: DC

  @type param ::
          {:generic_device_class, DC.generic_device_class() | :all}
          | {:specific_device_class, DC.specific_device_class() | :all}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    generic_class = Command.param(command, :generic_device_class, :all)
    generic_class_byte = encode_generic_class(generic_class)

    specific_class = Command.param(command, :specific_device_class, :all)
    specific_class_byte = encode_specific_class(generic_class, specific_class)

    <<generic_class_byte, specific_class_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<generic_class_byte, specific_class_byte>>) do
    generic_class = decode_generic_class(generic_class_byte)
    specific_class = decode_specific_class(generic_class, specific_class_byte)

    {:ok,
     [
       generic_device_class: generic_class,
       specific_device_class: specific_class
     ]}
  end

  @spec encode_generic_class(atom() | 0..255) :: 0..255
  defp encode_generic_class(:all), do: 0xFF
  defp encode_generic_class(g) when is_atom(g), do: DC.encode_generic(g)
  defp encode_generic_class(g) when g in 0..255, do: g

  @spec decode_generic_class(0..255) :: atom()
  defp decode_generic_class(0xFF), do: :all
  defp decode_generic_class(g), do: DC.decode_generic(g)

  @spec encode_specific_class(atom(), atom() | 0..255) :: 0..255
  defp encode_specific_class(_g, :all), do: 0xFF
  defp encode_specific_class(g, s) when is_atom(s), do: DC.encode_specific(g, s)
  defp encode_specific_class(_g, s) when s in 0..255, do: s

  @spec decode_specific_class(atom(), 0..255) :: atom()
  defp decode_specific_class(_g, 0xFF), do: :all
  defp decode_specific_class(g, s), do: DC.decode_specific(g, s)
end
