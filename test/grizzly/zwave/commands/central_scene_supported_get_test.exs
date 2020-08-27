defmodule Grizzly.ZWave.Commands.CentralSceneSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.CentralSceneSupportedGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = CentralSceneSupportedGet.new(params)
  end
end
