defmodule Grizzly.ZWave.Commands.SwitchBinaryGet do
  @moduledoc """
  Get the command value of a binary switch

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SwitchBinary

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :switch_binary_get,
      command_byte: 0x02,
      command_class: SwitchBinary
    }

    {:ok, command}
  end

  # TODO: make default implementation via using
  @impl Grizzly.ZWave.Command
  def decode_params(_), do: {:ok, []}

  # TODO: make default implementation via using
  @impl Grizzly.ZWave.Command
  def encode_params(_), do: <<>>
end
