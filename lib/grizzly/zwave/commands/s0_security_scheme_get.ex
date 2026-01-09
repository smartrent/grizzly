defmodule Grizzly.ZWave.Commands.S0SecuritySchemeGet do
  @moduledoc """
  A controlling device MUST send the Security Scheme Get command immediately
  after inclusion of a node that supports the Security Command Class.

  The Supported Security Schemes field is required by spec to always be 0x00.
  The 0th bit MUST be set to 0 indicating support for S0 (which is implied by
  the use of this command, so why it's required is beyond me). The remaining
  bits are reserved and must be set to 0 by a sending node.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<0::8>>

  @impl Grizzly.ZWave.Command
  def decode_params(<<_::8>>), do: {:ok, [supported_security_schemes: [:s0]]}
end
