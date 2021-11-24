defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = BarrierOperatorSignalSupportedGet.new(params)
  end
end
