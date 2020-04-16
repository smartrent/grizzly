defmodule Grizzly.ZWave.Commands.SwitchBinaryGet do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SwitchBinary

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_binary_get,
      command_byte: 0x02,
      command_class: SwitchBinary,
      impl: __MODULE__
    }

    {:ok, command}
  end

  # TODO: make default implementation via using
  @impl true
  def decode_params(_), do: {:ok, []}

  # TODO: make default implementation via using
  @impl true
  def encode_params(_), do: <<>>
end
