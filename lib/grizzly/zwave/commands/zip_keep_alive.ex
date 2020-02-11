defmodule Grizzly.ZWave.Commands.ZIPKeepAlive do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  @impl true
  def new(_params \\ []) do
    command = %Command{
      name: :keep_alive,
      command_class_name: :zip,
      command_byte: 0x03,
      command_class_byte: 0x23,
      params: [],
      handler: AckResponse,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_), do: <<>>

  @impl true
  def decode_params(_), do: []
end
