defmodule Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = WakeUpIntervalCapabilitiesGet.new(params)
  end
end
