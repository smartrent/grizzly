defmodule Grizzly.ZWave.Commands.MeterGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MeterGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = MeterGet.new(params)
  end
end
