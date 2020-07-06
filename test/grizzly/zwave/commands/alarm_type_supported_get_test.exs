defmodule Grizzly.ZWave.Commands.AlarmTypeSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmTypeSupportedGet

  test "creates the command and validates params" do
    {:ok, _command} = AlarmTypeSupportedGet.new([])
  end
end
