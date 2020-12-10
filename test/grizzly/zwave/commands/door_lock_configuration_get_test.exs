defmodule Grizzly.ZWave.Commands.DoorLockConfigurationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.DoorLockConfigurationGet

  test "creates the command and validates params" do
    {:ok, _command} = DoorLockConfigurationGet.new()
  end
end
