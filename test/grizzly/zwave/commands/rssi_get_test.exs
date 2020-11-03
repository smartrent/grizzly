defmodule Grizzly.ZWave.Commands.RssiGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.RssiGet

  test "creates the command and validates params" do
    {:ok, _command} = RssiGet.new()
  end
end
