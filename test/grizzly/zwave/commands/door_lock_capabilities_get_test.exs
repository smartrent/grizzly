defmodule Grizzly.ZWave.Commands.DoorLockCapabilitiesGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.DoorLockCapabilitiesGet

  test "creates the command and validates params" do
    {:ok, _command} = DoorLockCapabilitiesGet.new()
  end
end
