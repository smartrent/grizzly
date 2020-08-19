defmodule Grizzly.ZWave.Commands.AntitheftGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AntitheftGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = AntitheftGet.new(params)
  end
end
