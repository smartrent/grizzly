defmodule Grizzly.ZWave.Commands.NoOperation do
  @moduledoc """
  This commands does nothing other than test if the node is responding

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NoOperation

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :no_operation,
      command_byte: nil,
      command_class: NoOperation,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_), do: {:ok, []}
end
