defmodule Grizzly.ZWave.Commands.S0NetworkKeyVerify do
  @moduledoc """
  This command is sent in response to a Network Key Set command. If the receiving
  node is able to decrypt this command, it indicates that the included node has
  successfully received the network key and has been securely included.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.S0

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :s0_network_key_verify,
      command_byte: 0x07,
      command_class: S0,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
