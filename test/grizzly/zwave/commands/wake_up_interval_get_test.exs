defmodule Grizzly.ZWave.Commands.WakeUpIntervalGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WakeUpIntervalGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = WakeUpIntervalGet.new(params)
  end
end
