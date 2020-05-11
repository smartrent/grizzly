defmodule Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SensorMultilevelSupportedSensorGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = SensorMultilevelSupportedSensorGet.new(params)
  end
end
