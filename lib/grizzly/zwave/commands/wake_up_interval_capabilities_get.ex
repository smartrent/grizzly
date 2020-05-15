defmodule Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesGet do
  @moduledoc """
  This module implements the WAKE_UP_INTERVAL_CAPABILITIES_GET command of the
  COMMAND_CLASS_WAKE_UP command class.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @impl true
  def new(params) do
    command = %Command{
      name: :wake_up_interval_capabilities_get,
      command_byte: 0x09,
      command_class: WakeUp,
      params: params,
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
  def decode_params(_binary) do
    {:ok, []}
  end
end
