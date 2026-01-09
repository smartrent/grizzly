defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedReport do
  @moduledoc """
  This command returns a bit mask of signaling subsystem(s) supported by the sending node.

  Params:

    * `:subsystem_types` - the subsystem types supported

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.BarrierOperator

  @type param :: {:subsystem_types, [BarrierOperator.subsystem_type()]}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    subsystems = Command.param!(command, :subsystem_types)
    # Assumes only one bitmask is ever needed
    bitmask = BarrierOperator.subsystem_types_to_bitmask(subsystems)
    <<bitmask>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<bitmask>>) do
    subsystems = BarrierOperator.bitmask_to_subsystem_types(bitmask)

    {:ok, [subsystem_types: subsystems]}
  end
end
