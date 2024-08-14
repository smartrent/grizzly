defmodule Grizzly.ZWave.Commands.BasicGet do
  @moduledoc """
  This module implements the BASIC_GET command form the COMMAND_CLASS_BASIC
  command class

  Params: - none
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Basic

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :basic_get,
      command_byte: 0x02,
      command_class: Basic,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
