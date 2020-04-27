defmodule Grizzly.ZWave.Commands.SwitchMultilevelGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SwitchMultilevelGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = SwitchMultilevelGet.new(params)
  end
end
