defmodule Grizzly.ZWave.Commands.WakeUpIntervalSet do
  @moduledoc """
  This module implements the WAKE_UP_INTERVAL_SET command of the COMMAND_CLASS_WAKE_UP command class.

  Params:

    * `:seconds` - the time in seconds between Wake Up periods at the sending node

    * `:node_id` - the Wake Up destination NodeID configured at the sending node

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WakeUp

  @type param :: {:seconds, non_neg_integer} | {:node_id, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :wake_up_interval_set,
      command_byte: 0x04,
      command_class: WakeUp,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seconds = Command.param!(command, :seconds)
    node_id = Command.param!(command, :node_id)
    <<seconds::size(3)-unit(8), node_id>>
  end

  @impl true
  def decode_params(<<seconds::size(3)-unit(8), node_id>>) do
    {:ok, [seconds: seconds, node_id: node_id]}
  end
end
