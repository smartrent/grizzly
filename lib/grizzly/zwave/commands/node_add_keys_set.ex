defmodule Grizzly.ZWave.Commands.NodeAddKeysSet do
  @moduledoc """
  Command used to grant the security keys to the including node if the
  including node requested keys.

  This normally only needs to happen during the S2 bootstrapping process.

  Params:

    * `:seq_number` - the sequence number (required)
    * `:csa` - if the including node requested client side authentication,
      then setting this to `true` will allow for that node to preform CSA
      (required)
    * `:granted_keys` - the keys the including controller is granting to the
      including device, see `Grizzly.ZWave.Security` for more information
      (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Security

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    csa = Command.param!(command, :csa)
    accepted = Command.param!(command, :accept)
    granted_keys = Command.param!(command, :granted_keys)

    <<seq_number, 0::6, encode_csa(csa)::size(1), encode_accepted(accepted)::size(1),
      encode_granted_keys(granted_keys)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, _::6, csa::1, accepted::1, granted_keys>>) do
    {:ok,
     [
       seq_number: seq_number,
       csa: decode_csa(csa),
       accept: decode_accepted(accepted),
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
