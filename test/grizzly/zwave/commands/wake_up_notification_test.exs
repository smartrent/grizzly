defmodule Grizzly.ZWave.Commands.WakeUpNotificationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WakeUpNotification

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = WakeUpNotification.new(params)
  end
end
