defmodule Grizzly.ZWave.Commands.S2NetworkKeyVerify do
  @moduledoc """
  This command is used by a joining node to verify a newly exchanged key with
  the including node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(_params) do
    command = %Command{
      name: :s2_network_key_verify,
      command_byte: 0x0B,
      command_class: Security2,
      params: [],
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command), do: <<>>

  @impl Grizzly.ZWave.Command
  def decode_params(_binary), do: {:ok, []}
end
