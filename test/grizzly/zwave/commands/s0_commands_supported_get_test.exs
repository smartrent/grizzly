defmodule Grizzly.ZWave.Commands.S0CommandsSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.S0CommandsSupportedGet

  test "creates the command and validates params" do
    assert {:ok, _} = S0CommandsSupportedGet.new()
  end

  test "encodes params correctly" do
    assert {:ok, cmd} = S0CommandsSupportedGet.new()
    assert <<>> = S0CommandsSupportedGet.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, []} = S0CommandsSupportedGet.decode_params(<<>>)
  end
end
