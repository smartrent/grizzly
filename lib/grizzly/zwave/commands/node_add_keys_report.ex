defmodule Grizzly.ZWave.Commands.NodeAddKeysReport do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Security
  alias Grizzly.ZWave.CommandHandlers.WaitReport

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add_keys_report,
      command_class_name: :network_management_inclusion,
      command_byte: 0x11,
      command_class_byte: 0x34,
      params: params,
      handler: {WaitReport, complete_report: :node_add_keys_set},
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    csa = Command.param!(command, :csa)
    requested_keys = Command.param!(command, :requested_keys)

    <<seq_number, encode_csa(csa), encode_requested_keys(requested_keys)>>
  end

  @impl true
  def decode_params(<<seq_number, csa, requested_keys>>) do
    [
      seq_number: seq_number,
      csa: decode_csa(csa),
      requested_keys: decode_requested_keys(requested_keys)
    ]
  end

  def encode_csa(true), do: 0x01
  def encode_csa(false), do: 0x00

  def decode_csa(0x01), do: true
  def decode_csa(0x00), do: false

  def decode_requested_keys(requested_keys_mask), do: Security.byte_to_keys(requested_keys_mask)

  def encode_requested_keys(requested_keys), do: Security.keys_to_byte(requested_keys)
end
