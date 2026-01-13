defmodule Grizzly.ZWave.Commands.NodeInfoCachedReport do
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
  - `:command_classes` - a list of lists of command classes tagged by security attributes (optional default empty
    list)
  - `:basic_device_class` - the basic device class (required)
  - `:generic_device_class` - the generic device class (required)
  - `:specific_device_class` - the specific device class (required)
  """
  @behaviour Grizzly.ZWave.Command

  import Bitwise
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.DeviceClasses

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

  @type tagged_command_classes ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}
  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:status, status()}
          | {:age, 1..14}
          | {:listening?, boolean()}
          | {:command_classes, [tagged_command_classes]}
          | {:basic_device_class, DeviceClasses.basic_device_class()}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    status_byte = encode_status(Command.param!(command, :status))
    age = Command.param!(command, :age)
    listening_byte = encode_listening?(Command.param!(command, :listening?))
    command_classes = Command.param!(command, :command_classes)

    basic_device_class_byte =
      DeviceClasses.encode_basic(Command.param!(command, :basic_device_class))

    generic_device_class = Command.param!(command, :generic_device_class)

    specific_device_class_byte =
      DeviceClasses.encode_specific(
        generic_device_class,
        Command.param!(command, :specific_device_class)
      )

    optional_functionality_byte = encode_optional_functionality_byte(command_classes)

    # the `0x00` byte is a reserved byte for Z-Wave and must be set to 0x00
    <<seq_number, status_byte ||| age, listening_byte, optional_functionality_byte, 0x00,
      basic_device_class_byte, DeviceClasses.encode_generic(generic_device_class),
      specific_device_class_byte>> <> CommandClasses.command_class_list_to_binary(command_classes)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<seq_number, status::4, age::4, list?::1, _::7, _, _keys, basic_device_class_byte,
          generic_device_class_byte, specific_device_class_byte, command_classes::binary>>
      ) do
    basic_device_class =
      DeviceClasses.decode_basic(basic_device_class_byte)

    generic_device_class =
      DeviceClasses.decode_generic(generic_device_class_byte)

    specific_device_class =
      DeviceClasses.decode_specific(
        generic_device_class,
        specific_device_class_byte
      )

    {:ok,
     [
       seq_number: seq_number,
       basic_device_class: basic_device_class,
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       listening?: bit_to_bool(list?),
       command_classes: CommandClasses.command_class_list_from_binary(command_classes),
       status: decode_status(status),
       age: age
     ]}
  end

  def encode_status(_), do: 0
  def encode_command_classes(_), do: 0

  def encode_listening?(true), do: 0x80
  def encode_listening?(false), do: 0x00

  def encode_optional_functionality_byte([]), do: 0x00
  def encode_optional_functionality_byte(_), do: 0x80

  def decode_command_classes(""), do: []
  def decode_command_classes(_), do: []

  def decode_status(0x00), do: :ok
  def decode_status(0x01), do: :not_responding
  def decode_status(0x02), do: :unknown
end
