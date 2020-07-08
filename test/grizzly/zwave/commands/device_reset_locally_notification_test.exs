defmodule Grizzly.ZWave.Commands.DeviceResetLocallyNotificationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.DeviceResetLocallyNotification

  test "creates the command and validates params" do
    {:ok, _command} = DeviceResetLocallyNotification.new([])
  end
end
