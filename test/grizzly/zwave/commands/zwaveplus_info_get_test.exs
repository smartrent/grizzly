defmodule Grizzly.ZWave.Commands.ZwaveplusInfoGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZwaveplusInfoGet

  test "creates the command and validates params" do
    {:ok, _command} = ZwaveplusInfoGet.new()
  end
end
