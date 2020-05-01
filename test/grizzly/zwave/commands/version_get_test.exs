defmodule Grizzly.ZWave.Commands.VersionGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.VersionGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = VersionGet.new(params)
  end
end
