defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityReport do
  @moduledoc """
  Command to query the capabilities of one individual endpoint or aggregated
  end point

  Params:

  * `:seq_number` - the sequence number for this command
  * `:node_id` - the node id that has the end point to query
  * `:end_point` - the end point to query
  * `:generic_device_class` - the generic device class
  * `:specific_device_class` - the specific device class
  * `:command_classes` - the command class list

  Sending this command to a device with the end point `0` will return the
  information about the device it self. This is the same as sending the
  `Grizzly.ZWave.Commands.NodeInfoCachedGet` command.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.DeviceClasses
  alias Grizzly.ZWave.NodeId

  @type param() ::
          {:seq_number, ZWave.seq_number()}
          | {:node_id, ZWave.node_id()}
          | {:end_point, 0..127}
          | {:generic_device_class, DeviceClasses.generic_device_class()}
          | {:specific_device_class, DeviceClasses.specific_device_class()}
          | {:command_classes, list()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    end_point = Command.param!(command, :end_point)

    generic_device_class = Command.param!(command, :generic_device_class)

    specific_device_class_byte = encode_specific_device_class(generic_device_class, command)
    generic_device_class_byte = encode_generic_device_class(generic_device_class)

    cc_binary =
      command
      |> Command.param!(:command_classes)
      |> CommandClasses.command_class_list_to_binary()

    delimiter =
      <<cc_list_byte_size(cc_binary), 0::1, end_point::7, generic_device_class_byte,
        specific_device_class_byte, cc_binary::binary>>

    <<seq_number, NodeId.encode_extended(node_id, delimiter: delimiter)::binary>>
  end

  defp cc_list_byte_size(<<0>>), do: 0
  defp cc_list_byte_size(binary), do: byte_size(binary)

  defp encode_generic_device_class(0), do: 0
  defp encode_generic_device_class(nil), do: 0

  defp encode_generic_device_class(gen_dev_class),
    do: DeviceClasses.encode_generic(gen_dev_class)

  defp encode_specific_device_class(0, _command), do: 0
  defp encode_specific_device_class(nil, _command), do: 0

  defp encode_specific_device_class(gen_dev_class, command) do
    case Command.param(command, :specific_device_class) do
      nil ->
        0

      0 ->
        0

      spec_dev_class ->
        DeviceClasses.encode_specific(gen_dev_class, spec_dev_class)
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, node_id, 0x00, _reserved::1, end_point::7, 0x00, 0x00, 0x00>>) do
    {:ok,
     [
       seq_number: seq_number,
       node_id: node_id,
       generic_device_class: :unknown,
       specific_device_class: :unknown,
       command_classes: [],
       end_point: end_point
     ]}
  end

  def decode_params(<<seq_number, params::binary>>) do
    <<_node_id, cc_len, _reserved::1, end_point::7, generic_device_class, specific_device_class,
      command_classes::binary-size(cc_len), _rest::binary>> = params

    generic_device_class =
      DeviceClasses.decode_generic(generic_device_class)

    specific_device_class =
      DeviceClasses.decode_specific(
        generic_device_class,
        specific_device_class
      )

    delimiter_size = cc_len + 4

    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(params, delimiter_size: delimiter_size),
       end_point: end_point,
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       command_classes: CommandClasses.command_class_list_from_binary(command_classes)
     ]}
  end
end
