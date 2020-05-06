defmodule Grizzly.ZWave.Commands.BatteryGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BatteryGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = BatteryGet.new(params)
  end
end
