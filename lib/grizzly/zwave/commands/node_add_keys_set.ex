defmodule Grizzly.ZWave.Commands.NodeAddKeysSet do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, Security}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add_keys_set,
      command_byte: 0x12,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    csa = Command.param!(command, :csa)
    accepted = Command.param!(command, :accept)
    granted_keys = Command.param!(command, :granted_keys)

    <<seq_number, 0::size(6), encode_csa(csa)::size(1), encode_accepted(accepted)::size(1),
      encode_granted_keys(granted_keys)>>
  end

  @impl true
  def decode_params(<<seq_number, _::size(6), csa::size(1), accepted::size(1), granted_keys>>) do
    {:ok,
     [
       seq_number: seq_number,
       csa: decode_csa(csa),
       accepted: decode_accepted(accepted),
       granted_keys: decode_granted_keys(granted_keys)
     ]}
  end

  def encode_csa(true), do: 1
  def encode_csa(false), do: 0

  def decode_csa(1), do: true
  def decode_csa(0), do: true

  def encode_accepted(true), do: 1
  def encode_accepted(false), do: 0

  def decode_accepted(1), do: true
  def decode_accepted(0), do: false

  def encode_granted_keys(granted_keys), do: Security.keys_to_byte(granted_keys)

  def decode_granted_keys(granted_keys), do: Security.byte_to_keys(granted_keys)
end
