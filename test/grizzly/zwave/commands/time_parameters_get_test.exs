defmodule Grizzly.ZWave.Commands.TimeParametersGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.TimeParametersGet

  test "creates the command and validates params" do
    {:ok, _command} = TimeParametersGet.new([])
  end
end
