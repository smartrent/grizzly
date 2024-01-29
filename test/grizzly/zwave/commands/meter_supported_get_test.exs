defmodule Grizzly.ZWave.Commands.MeterSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MeterSupportedGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = MeterSupportedGet.new(params)
  end
end
