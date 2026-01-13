defmodule Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesReport do
  @moduledoc """
  This module implements the WAKE_UP_INTERVAL_CAPABILITIES_REPORT command of the COMMAND_CLASS_WAKE_UP command class.

  Params:

    * `:minimum_seconds` - the minimum Wake Up Interval supported by the sending node - v2
    * `:maximum_seconds` - the maximum Wake Up Interval supported by the sending node - v2
    * `:default_seconds` - the default Wake Up Interval value for the sending node. - v2
    * `:step_seconds` - the resolution of valid Wake Up Intervals values for the sending node - v2
    * `:on_demand` - whether the supporting node supports the Wake Up On Demand functionality - v3

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param ::
          {:minimum_seconds, non_neg_integer}
          | {:minimum_seconds, non_neg_integer}
          | {:maximum_seconds, non_neg_integer}
          | {:default_seconds, non_neg_integer}
          | {:step_seconds, non_neg_integer}
          | {:on_demand, boolean}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    minimum_seconds = Command.param!(command, :minimum_seconds)
    maximum_seconds = Command.param!(command, :maximum_seconds)
    default_seconds = Command.param!(command, :default_seconds)
    step_seconds = Command.param!(command, :step_seconds)
    on_demand = Command.param(command, :on_demand)

    if on_demand == nil do
      # v2
      <<
        minimum_seconds::24,
        maximum_seconds::24,
        default_seconds::24,
        step_seconds::24
      >>
    else
      # v3
      <<
        minimum_seconds::24,
        maximum_seconds::24,
        default_seconds::24,
        step_seconds::24,
        0x00::7,
        encode_on_demand(on_demand)::size(1)
      >>
    end
  end

  @impl Grizzly.ZWave.Command
  # v2
  def decode_params(
        _spec,
        <<
          minimum_seconds::24,
          maximum_seconds::24,
          default_seconds::24,
          step_seconds::24
        >>
      ) do
    {:ok,
     [
       minimum_seconds: minimum_seconds,
       maximum_seconds: maximum_seconds,
       default_seconds: default_seconds,
       step_seconds: step_seconds
     ]}
  end

  # v3
  def decode_params(
        _spec,
        <<minimum_seconds::24, maximum_seconds::24, default_seconds::24, step_seconds::24,
          0x00::7, on_demand_byte::1>>
      ) do
    {:ok,
     [
       minimum_seconds: minimum_seconds,
       maximum_seconds: maximum_seconds,
       default_seconds: default_seconds,
       step_seconds: step_seconds,
       on_demand: on_demand_byte == 0x01
     ]}
  end

  defp encode_on_demand(false), do: 0x00
  defp encode_on_demand(true), do: 0x01
end
