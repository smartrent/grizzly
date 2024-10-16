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
  alias Grizzly.ZWave.CommandClasses.MultiChannel
  alias Grizzly.ZWave.DeviceClasses, as: DC

  @type param ::
          {:generic_device_class, DC.generic_device_class() | :all}
          | {:specific_device_class, DC.specific_device_class() | :all}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_endpoint_find,
      command_byte: 0x0B,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    generic_class = Command.param(command, :generic_device_class, :all)
    generic_class_byte = encode_generic_class(generic_class)

    specific_class = Command.param(command, :specific_device_class, :all)
    specific_class_byte = encode_specific_class(generic_class, specific_class)

    <<generic_class_byte, specific_class_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<generic_class_byte, specific_class_byte>>) do
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
  defp encode_generic_class(g) when is_atom(g), do: DC.generic_device_class_to_byte(g)
  defp encode_generic_class(g) when g in 0..255, do: g

  @spec decode_generic_class(0..255) :: atom()
  defp decode_generic_class(0xFF), do: :all
  defp decode_generic_class(g), do: elem(DC.generic_device_class_from_byte(g), 1)

  @spec encode_specific_class(atom(), atom() | 0..255) :: 0..255
  defp encode_specific_class(_g, :all), do: 0xFF
  defp encode_specific_class(g, s) when is_atom(s), do: DC.specific_device_class_to_byte(g, s)
  defp encode_specific_class(_g, s) when s in 0..255, do: s

  @spec decode_specific_class(atom(), 0..255) :: atom()
  defp decode_specific_class(_g, 0xFF), do: :all
  defp decode_specific_class(g, s), do: elem(DC.specific_device_class_from_byte(g, s), 1)
end
