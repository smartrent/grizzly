defmodule Grizzly.ZWave.Commands.S2CommandsSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.S2CommandsSupportedGet

  test "creates the command and validates params" do
    assert {:ok, _} = S2CommandsSupportedGet.new()
  end

  test "encodes params correctly" do
    assert {:ok, cmd} = S2CommandsSupportedGet.new()
    assert <<>> = S2CommandsSupportedGet.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, []} = S2CommandsSupportedGet.decode_params(<<>>)
  end
end
