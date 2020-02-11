defmodule Grizzly.ZWave.Commands.SwitchBinaryGet do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandHandlers.WaitReport

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_binary_get,
      command_class_name: :switch_binary,
      command_class_byte: 0x25,
      command_byte: 0x02,
      handler: {WaitReport, complete_report: :switch_binary_report},
      impl: __MODULE__
    }

    {:ok, command}
  end

  # TODO: make default implementation via using
  @impl true
  def decode_params(_), do: []

  # TODO: make default implementation via using
  @impl true
  def encode_params(_), do: <<>>
end
