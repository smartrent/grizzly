defmodule Grizzly.ZWave.Commands.BarrierOperatorGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BarrierOperatorGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = BarrierOperatorGet.new(params)
  end
end
