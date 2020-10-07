defmodule Grizzly.ZWave.Commands.PowerlevelGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PowerlevelGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = PowerlevelGet.new(params)
  end
end
