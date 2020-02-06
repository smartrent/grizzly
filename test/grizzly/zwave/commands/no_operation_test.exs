defmodule Grizzly.ZWave.Commands.NoOperationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NoOperation

  test "creates the command" do
    {:ok, _command} = NoOperation.new([])
  end
end
