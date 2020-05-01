defmodule Grizzly.ZWave.Commands.ManufacturerSpecificGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ManufacturerSpecificGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ManufacturerSpecificGet.new(params)
  end
end
