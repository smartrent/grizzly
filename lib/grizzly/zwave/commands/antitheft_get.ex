defmodule Grizzly.ZWave.Commands.AntitheftGet do
  @moduledoc """
  This command is used to request the locked/unlocked state of a supporting
  node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Antitheft

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :antitheft_get,
      command_byte: 0x02,
      command_class: Antitheft,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
