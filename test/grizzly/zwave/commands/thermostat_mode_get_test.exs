defmodule Grizzly.ZWave.Commands.ThermostatModeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatModeGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ThermostatModeGet.new(params)
  end
end
