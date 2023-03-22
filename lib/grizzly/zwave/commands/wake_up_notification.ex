defmodule Grizzly.ZWave.Commands.WakeUpNotification do
  @moduledoc """
  This module implements the WAKE_UP_NOTIFICATION command of the
  COMMAND_CLASS_WAKE_UP command class

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :wake_up_notification,
      command_byte: 0x07,
      command_class: WakeUp,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
