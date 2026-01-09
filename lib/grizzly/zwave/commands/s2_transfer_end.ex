defmodule Grizzly.ZWave.Commands.S2TransferEnd do
  @moduledoc """
  This command is used by the including node to complete the verification of
  each individual key exchange while the joining node uses this command to
  complete the S2 bootstrapping process after all granted keys have been
  successfully exchanged.

  The joining node MUST send this command after all granted keys have been
  verified.

  This command MUST be ignored if Learn mode and Add Node mode are both
  disabled.
  """
  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command

  @type param :: {:key_verified, boolean(), key_request_complete: boolean()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    key_verified = Command.param!(command, :key_verified)
    key_request_complete = Command.param!(command, :key_request_complete)

    <<0::6, bool_to_bit(key_verified)::1, bool_to_bit(key_request_complete)::1>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::6, key_verified::1, key_request_complete::1>>) do
    key_verified = bit_to_bool(key_verified)
    key_request_complete = bit_to_bool(key_request_complete)

    {:ok, [key_verified: key_verified, key_request_complete: key_request_complete]}
  end
end
