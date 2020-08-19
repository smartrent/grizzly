defmodule Grizzly.ZWave.Commands.AntitheftUnlockGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AntitheftUnlockGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = AntitheftUnlockGet.new(params)
  end
end
