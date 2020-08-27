defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.CentralSceneConfigurationGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = CentralSceneConfigurationGet.new(params)
  end
end
