defmodule Grizzly.ZWave.Commands.ThermostatFanModeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatFanModeGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ThermostatFanModeGet.new(params)
  end
end
