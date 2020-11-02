defmodule Grizzly.ZWave.Commands.ClockGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ClockGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ClockGet.new(params)
  end
end
