defmodule Grizzly.ZWave.Commands.NodeNameGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeNameGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = NodeNameGet.new(params)
  end
end
