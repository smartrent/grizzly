defmodule Grizzly.ZWave.Commands.ExtendedNodeAddStatus do
  @moduledoc """
  ExtendedNodeAddStatus

  This command is used to report the result of a node inclusion of an a node
  with an extended node id, normally a long range node.

  Params:

    * `:seq_number` - the sequence number of the inclusion command
    * `:status` - the status of the inclusion
    * `:node_id` - the new id of the new Z-Wave node
    * `:basic_device_class` - the Z-Wave basic device class
    * `:generic_device_class` - the Z-Wave generic device class
    * `:specific_device_class` - the Z-Wave specific device class
    * `:command_classes` - a list of the command class the device supports, tagged by their security level
       used only if the device was included securely
    * `:granted_keys` - the security keys granted during S2 inclusion
    * `:kex_fail_type` - the error that occurred in the S2 bootstrapping

  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, Security}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type tagged_command_classes() ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}

  @type param() ::
          {:node_id, Grizzly.node_id()}
          | {:status, NetworkManagementInclusion.node_add_status()}
          | {:seq_number, Grizzly.seq_number()}
          | {:basic_device_class, byte()}
          | {:generic_device_class, byte()}
          | {:specific_device_class, byte()}
          | {:command_classes, [tagged_command_classes()]}
          | {:granted_keys, [Security.key()]}
          | {:kex_fail_type, Security.key_exchange_fail_type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    # TODO: validate params
    command = %Command{
      name: :extended_node_add_status,
      command_byte: 0x16,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    status = Command.param!(command, :status)
    seq_number = Command.param!(command, :seq_number)
    status_byte = NetworkManagementInclusion.node_add_status_to_byte(status)

    if status == :failed do
      <<seq_number, status_byte, node_id::16, 0x01>>
    else
      basic_device_class = Command.param!(command, :basic_device_class)
      generic_device_class = Command.param!(command, :generic_device_class)
      specific_device_class = Command.param!(command, :specific_device_class)
      command_classes = Command.param!(command, :command_classes)
      extra_ccs? = not Enum.empty?(command_classes)

      # We add 6 to the length of the command classes to account for the 3 device
      # classes 2 Z-Wave protocol bytes and the node info length byte.
      # Also add the number of command classes plus 4 bytes for the separators
      # See SDS13784 4.4.8.2 for more details
      node_info_length = 6 + cc_count(command_classes)

      extra_ccs_bit = if extra_ccs?, do: 1, else: 0

      # TODO: fix opt func bit (after the extra_ccs bit)
      <<seq_number, status_byte, node_id::16, node_info_length, extra_ccs_bit::1, 0x00::7, 0x00,
        basic_device_class, generic_device_class,
        specific_device_class>> <>
        CommandClasses.command_class_list_to_binary(command_classes) <>
        add_keys_granted_and_fail_type(command)
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, status_byte, node_id::16, node_info_bin::binary>>) do
    node_info = NetworkManagementInclusion.parse_node_info(node_info_bin)

    params =
      %{
        status: NetworkManagementInclusion.parse_node_add_status(status_byte),
        seq_number: seq_number,
        node_id: node_id
      }
      |> Map.merge(node_info)
      |> Enum.into([])

    {:ok, params}
  end

  def decode_params(<<seq_number, status_byte, node_id::16, 0x01>>) do
    {:ok,
     [
       status: NetworkManagementInclusion.parse_node_add_status(status_byte),
       seq_number: seq_number,
       node_id: node_id,
       basic_device_class: :unknown,
       generic_device_class: :unknown,
       specific_device_class: :unknown,
       command_classes: []
     ]}
  end

  defp add_keys_granted_and_fail_type(command) do
    keys = Command.param!(command, :granted_keys)
    kex_failed_type = Command.param!(command, :kex_fail_type)

    <<Security.keys_to_byte(keys), Security.failed_type_to_byte(kex_failed_type)>>
  end

  defp cc_count(tagged_command_classes) do
    padding = get_padding(tagged_command_classes)
    cc_length = tagged_command_classes |> Keyword.values() |> List.flatten() |> length()

    cc_length + padding
  end

  defp get_padding(tagged_command_classes) do
    Enum.reduce(tagged_command_classes, 0, fn
      {_, []}, padding ->
        padding

      {:secure_supported, _}, padding ->
        padding + 2

      {other, _}, padding when other in [:non_secure_controlled, :secure_controlled] ->
        padding + 1

      _, padding ->
        padding
    end)
  end
end
