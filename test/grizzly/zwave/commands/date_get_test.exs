defmodule Grizzly.ZWave.Commands.DateGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.DateGet

  test "creates the command and validates params" do
    {:ok, _command} = DateGet.new([])
  end
end
