defmodule Grizzly.ZWave.Commands.ThermostatFanStateGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatFanStateGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ThermostatFanStateGet.new(params)
  end
end
