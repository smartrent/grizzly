defmodule Grizzly.ZWave.Commands.MultiChannelEndpointFind do
  @moduledoc """
  This command is used to request End Points having a specific Generic or Specific Device Class in End
  Points.

  Params:

  * `:generic_device_class` - a generic device class (required)

  * `:specific_device_class` - a specific device class (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DeviceClasses}
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param ::
          {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}

  @impl true
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

  @impl true
  def encode_params(command) do
    generic_device_class = Command.param!(command, :generic_device_class)
    generic_device_class_byte = DeviceClasses.generic_device_class_to_byte(generic_device_class)

    specific_device_class_byte =
      DeviceClasses.specific_device_class_to_byte(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    <<generic_device_class_byte, specific_device_class_byte>>
  end

  @impl true
  def decode_params(<<generic_device_class_byte, specific_device_class_byte>>) do
    {:ok, generic_device_class} =
      DeviceClasses.generic_device_class_from_byte(generic_device_class_byte)

    {:ok, specific_device_class} =
      DeviceClasses.specific_device_class_from_byte(
        generic_device_class,
        specific_device_class_byte
      )

    {:ok,
     [
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class
     ]}
  end
end
