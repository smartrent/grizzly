defmodule Grizzly.ZWave.Commands.WakeUpNoMoreInformation do
  @moduledoc """
  This module implements the WAKE_UP_NO_MORE_INFORMATION command of the
  COMMAND_CLASS_WAKE_UP command class

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :wake_up_no_more_information,
      command_byte: 0x08,
      command_class: WakeUp
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
