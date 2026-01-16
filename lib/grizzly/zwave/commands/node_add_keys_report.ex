defmodule Grizzly.ZWave.Commands.NodeAddKeysReport do
  @moduledoc """
  Command to report the security keys requested by an including node if that
  node is participating in S2 bootstrapping.

  Params:

    * `:seq_number` - the sequence number of the command (required)
    * `:csa` - if the including node is doing client side authentication
      (require)
    * `:requested_keys` - a list of requested security keys see
      `Grizzly.ZWave.Security` for more information. (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Security

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    csa = Command.param!(command, :csa)
    requested_keys = Command.param!(command, :requested_keys)

    <<seq_number, encode_csa(csa), Security.keys_to_byte(requested_keys)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, csa, requested_keys>>) do
    {:ok,
     [
       seq_number: seq_number,
       csa: decode_csa(csa),
       requested_keys: Security.byte_to_keys(requested_keys)
     ]}
  end

  defp encode_csa(true), do: 0x01
  defp encode_csa(false), do: 0x00

  defp decode_csa(0x01), do: true
  defp decode_csa(0x00), do: false
end
