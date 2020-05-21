defmodule Grizzly.ZWave.Commands.FirmwareMDGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirmwareMDGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = FirmwareMDGet.new(params)
  end
end
