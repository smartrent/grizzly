defmodule Grizzly.ZWave.Commands.TimeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.TimeGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = TimeGet.new(params)
  end
end
