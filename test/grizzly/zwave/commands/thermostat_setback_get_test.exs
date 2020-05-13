defmodule Grizzly.ZWave.Commands.ThermostatSetbackGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ThermostatSetbackGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ThermostatSetbackGet.new(params)
  end
end
