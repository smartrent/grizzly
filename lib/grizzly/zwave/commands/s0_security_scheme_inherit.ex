defmodule Grizzly.ZWave.Commands.S0SecuritySchemeInherit do
  @moduledoc """
  After a controller has been securely included into a network, this command must
  be sent to the controller to indicate that it should inherit the same S0
  security scheme as the including controller.
  """
  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<0::8>>

  @impl Grizzly.ZWave.Command
  def decode_params(<<_::8>>), do: {:ok, [supported_security_schemes: [:s0]]}
end
