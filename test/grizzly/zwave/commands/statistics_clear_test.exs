defmodule Grizzly.ZWave.Commands.StatisticsClearTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.StatisticsClear

  test "creates the command and validates params" do
    {:ok, _command} = StatisticsClear.new()
  end
end
