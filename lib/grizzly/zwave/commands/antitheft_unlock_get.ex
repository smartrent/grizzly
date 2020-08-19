defmodule Grizzly.ZWave.Commands.AntitheftUnlockGet do
  @moduledoc """
  This command is used to request the locked/unlocked state of the node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AntitheftUnlock

  @impl true
  def new(params \\ []) do
    command = %Command{
      name: :antitheft_unlock_get,
      command_byte: 0x01,
      command_class: AntitheftUnlock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
