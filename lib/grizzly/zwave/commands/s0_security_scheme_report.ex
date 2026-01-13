defmodule Grizzly.ZWave.Commands.S0SecuritySchemeReport do
  @moduledoc """
  This command is used to advertised S0 support by the node being included. Upon
  reception, the including controller MUST immediately send the network key using
  the Network Key Set command.

  The Supported Security Schemes field is required by spec to always be 0x00.
  The 0th bit MUST be set to 0 indicating support for S0 (which is implied by
  the use of this command, so why it's required is beyond me). The remaining
  bits are reserved and must be set to 0 by a sending node.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, _command), do: <<0::8>>

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_::8>>), do: {:ok, [supported_security_schemes: [:s0]]}
end
