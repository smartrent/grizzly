defmodule Grizzly.ZWave.Commands.WakeUpNotification do
  @moduledoc """
  This module implements the WAKE_UP_NOTIFICATION command of the
  COMMAND_CLASS_WAKE_UP command class

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :wake_up_notification,
      command_byte: 0x07,
      command_class: WakeUp,
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
