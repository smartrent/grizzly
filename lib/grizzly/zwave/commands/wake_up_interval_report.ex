defmodule Grizzly.ZWave.Commands.WakeUpIntervalReport do
  @moduledoc """
  This module implements the WAKE_UP_INTERVAL_REPORT command of the
  COMMAND_CLASS_WAKE_UP command class.

  Params:

    * `:seconds` - the time in seconds between Wake Up periods at the sending
      node (required)
    * `:node_id` - the Wake Up destination NodeID configured at the sending node
      (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @type param :: {:seconds, non_neg_integer} | {:node_id, byte}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :wake_up_interval_report,
      command_byte: 0x06,
      command_class: WakeUp,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seconds = Command.param!(command, :seconds)
    node_id = Command.param!(command, :node_id)
    <<seconds::24, node_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seconds::24, node_id>>) do
    {:ok, [seconds: seconds, node_id: node_id]}
  end
end
