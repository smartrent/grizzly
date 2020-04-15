defmodule Grizzly.ZWave.Commands.ZIPKeepAlive do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ZIP

  @impl true
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :keep_alive,
      command_byte: 0x03,
      command_class: ZIP,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_), do: <<>>

  @impl true
  def decode_params(_), do: []
end
