defmodule Grizzly.ZWave.Commands.WindowCoveringSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WindowCoveringSupportedGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = WindowCoveringSupportedGet.new(params)
  end
end
