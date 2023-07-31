defmodule Grizzly.ZWave.Commands.S0NonceReport do
  @moduledoc """
  This command is used to request an external nonce from the receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.S0

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :s0_nonce_report,
      command_byte: 0x80,
      command_class: S0,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    nonce = Command.param!(command, :nonce)
    <<nonce::binary-size(8)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<nonce::binary-size(8)>>), do: {:ok, [nonce: nonce]}
end
