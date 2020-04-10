defmodule Grizzly.ZWave.Commands.NodeInfoCacheReport do
  @moduledoc """
  Report the cached node information

  This command is normally used to respond to the `NodeInfoCacheGet` command

  Params:

  - `:seq_number` - the sequence number of the network command, normally from
    from the `NodeInfoCacheGet` command (required)
  - `:status` - the status fo the node information (required)
  - `:age` - the age of the cache data. A number that is expressed `2 ^ n`
    minutes (required)
  - `:listening?` - if the node is listening node or sleeping node (required)
  - `:command_classes` - a list of command classes (optional default empty
    list)
  - `:basic_device_class` - the basic device class (required)
  - `:generic_device_class` - the generic device class (required)
  - `:specific_device_class` - the specific device class (required)
  """
  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.{CommandClasses, DeviceClasses}
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  @typedoc """
  The status of the refresh of the node information cache

  Status:
    - `:ok` - the requested node id could found and up-to-date information is
      returned
    - `:not_responding` - the requested node id could be found but fresh
      information could not be retrieved
    - `:unknown` - the node id is unknown
  """
  @type status :: :ok | :not_responding | :unknown

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:status, status()}
          | {:age, 1..14}
          | {:listening?, boolean()}
          | {:command_classes, [CommandClasses.command_class()]}
          | {:secure_command_classes, [CommandClasses.command_class()]}
          | {:basic_device_class, DeviceClasses.basic_device_class()}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}

  @impl true
  @spec new([param]) :: {:ok, Grizzly.ZWave.Command.t()}
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_info_cache_report,
      command_byte: 0x04,
      command_class_name: :network_management_proxy,
      command_class_byte: 0x52,
      params: params,
      handler: AckResponse,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    status_byte = encode_status(Command.param!(command, :status))
    age = Command.param!(command, :age)
    listening_byte = encode_listening?(Command.param!(command, :listening?))
    command_classes = Command.param!(command, :command_classes)

    basic_device_class_byte =
      DeviceClasses.basic_device_class_to_byte(Command.param!(command, :basic_device_class))

    generic_device_class = Command.param!(command, :generic_device_class)

    specific_device_class_byte =
      DeviceClasses.specific_device_class_to_byte(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    optional_functionality_byte = encode_optional_functionality_byte(command_classes)

    # the `0x00` byte is a reserved byte for Z-Wave and must be set to 0x00
    <<seq_number, status_byte ||| age, listening_byte, optional_functionality_byte, 0x00,
      basic_device_class_byte, DeviceClasses.generic_device_class_to_byte(generic_device_class),
      specific_device_class_byte>> <> CommandClasses.command_class_list_to_binary(command_classes)
  end

  @impl true
  def decode_params(
        <<seq_number, status::size(4), age::size(4), list?::size(1), _::size(7), _, 0x00,
          basic_device_class_byte, generic_device_class_byte, specific_device_class_byte,
          command_classes::binary>>
      ) do
    {:ok, basic_device_class} =
      DeviceClasses.basic_device_class_from_byte(basic_device_class_byte)

    {:ok, generic_device_class} =
      DeviceClasses.generic_device_class_from_byte(generic_device_class_byte)

    {:ok, specific_device_class} =
      DeviceClasses.specific_device_class_from_byte(
        generic_device_class,
        specific_device_class_byte
      )

    [
      seq_number: seq_number,
      basic_device_class: basic_device_class,
      generic_device_class: generic_device_class,
      specific_device_class: specific_device_class,
      listening?: bit_to_bool(list?),
      command_classes: CommandClasses.command_class_list_from_binary(command_classes),
      status: decode_status(status),
      age: age
    ]
  end

  def encode_status(_), do: 0
  def encode_command_classes(_), do: 0

  def encode_listening?(true), do: 0x80
  def encode_listening?(false), do: 0x00

  def bit_to_bool(bit), do: bit == 1

  def encode_optional_functionality_byte([]), do: 0x00
  def encode_optional_functionality_byte(_), do: 0x80

  def decode_command_classes(""), do: []
  def decode_command_classes(_), do: []

  def decode_status(0x00), do: :ok
  def decode_status(0x01), do: :not_responding
  def decode_status(0x02), do: :unknown
end
