defmodule Grizzly.ZWave.Commands.TimeOffsetGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.TimeOffsetGet

  test "creates the command and validates params" do
    {:ok, _command} = TimeOffsetGet.new([])
  end
end
