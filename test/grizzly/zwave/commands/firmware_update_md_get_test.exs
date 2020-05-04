defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareUpdateMDGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = FirmwareUpdateMDGet.new(params)
  end
end
