defmodule Grizzly.ZWave.Commands.S0NonceGet do
  @moduledoc """
  This command is used to request an external nonce from the receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.S0

  @impl Grizzly.ZWave.Command
  def new(_params \\ []) do
    command = %Command{
      name: :s0_nonce_get,
      command_byte: 0x40,
      command_class: S0,
      params: []
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
