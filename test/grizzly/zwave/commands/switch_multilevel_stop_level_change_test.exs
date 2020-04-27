defmodule Grizzly.ZWave.Commands.SwitchMultilevelStopLevelChangeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SwitchMultilevelStopLevelChange

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = SwitchMultilevelStopLevelChange.new(params)
  end
end
