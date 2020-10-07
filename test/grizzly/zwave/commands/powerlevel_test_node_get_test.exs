defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PowerlevelTestNodeGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = PowerlevelTestNodeGet.new(params)
  end
end
