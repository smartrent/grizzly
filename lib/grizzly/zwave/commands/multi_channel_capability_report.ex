defmodule Grizzly.ZWave.Commands.MultiChannelCapabilityReport do
  @moduledoc """
  This command is used to advertise the Generic and Specific Device Class and the supported command
  classes of an End Point.

  Params:

    * `:end_point` - the end point capabilities are being reported about (required)

    * `:dynamic?` - whether the end point is dynamic (required - true or false)

    * `:generic_device_class` - the generic device class for the end point (required)

    * `:specific_device_class` - the specific device class for the end point (required)

    * `:command_classes` - the command classes supported by the end point (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.CommandClasses.MultiChannel
  alias Grizzly.ZWave.DeviceClasses

  @type param ::
          {:end_point, MultiChannel.end_point()}
          | {:dynamic?, boolean()}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}
          | {:command_classes, [CommandClasses.command_class()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_capability_report,
      command_byte: 0x0A,
      command_class: MultiChannel,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    end_point = Command.param!(command, :end_point)
    dynamic_bit = encode_dynamic?(Command.param!(command, :dynamic?))
    command_classes = Command.param!(command, :command_classes)

    generic_device_class = Command.param!(command, :generic_device_class)
    generic_device_class_byte = DeviceClasses.encode_generic(generic_device_class)

    specific_device_class_byte =
      DeviceClasses.encode_specific(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    <<dynamic_bit::1, end_point::7, generic_device_class_byte, specific_device_class_byte>> <>
      encode_command_classes(command_classes)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(
        <<dynamic_bit::1, end_point::7, generic_device_class_byte, specific_device_class_byte,
          command_classes_binary::binary>>
      ) do
    command_classes = decode_command_classes(command_classes_binary)
    dynamic? = decode_dynamic?(dynamic_bit)

    generic_device_class =
      DeviceClasses.decode_generic(generic_device_class_byte)

    specific_device_class =
      DeviceClasses.decode_specific(
        generic_device_class,
        specific_device_class_byte
      )

    {:ok,
     [
       end_point: end_point,
       dynamic?: dynamic?,
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       command_classes: command_classes
     ]}
  end

  defp encode_dynamic?(false), do: 0x00
  defp encode_dynamic?(true), do: 0x01

  defp decode_dynamic?(0x00), do: false
  defp decode_dynamic?(0x01), do: true

  defp encode_command_classes(command_classes) do
    for command_class <- command_classes, into: <<>> do
      <<CommandClasses.to_byte(command_class)>>
    end
  end

  defp decode_command_classes(binary) do
    for byte <- :erlang.binary_to_list(binary) do
      {:ok, cc} = CommandClasses.from_byte(byte)
      cc
    end
  end
end
