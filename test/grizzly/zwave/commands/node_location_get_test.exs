defmodule Grizzly.ZWave.Commands.NodeLocationGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeLocationGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = NodeLocationGet.new(params)
  end
end
