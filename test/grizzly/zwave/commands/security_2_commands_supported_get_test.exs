defmodule Grizzly.ZWave.Commands.Security2CommandsSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.Security2CommandsSupportedGet

  test "creates the command and validates params" do
    assert {:ok, _} = Security2CommandsSupportedGet.new()
  end

  test "encodes params correctly" do
    assert {:ok, cmd} = Security2CommandsSupportedGet.new()
    assert <<>> = Security2CommandsSupportedGet.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, []} = Security2CommandsSupportedGet.decode_params(<<>>)
  end
end
