defmodule Grizzly.ZWave.Commands.ThermostatOperatingStateGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatOperatingStateGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ThermostatOperatingStateGet.new(params)
  end
end
