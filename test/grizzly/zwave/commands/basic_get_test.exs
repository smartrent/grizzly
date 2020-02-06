defmodule Grizzly.ZWave.Commands.BasicGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BasicGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = BasicGet.new(params)
  end
end
