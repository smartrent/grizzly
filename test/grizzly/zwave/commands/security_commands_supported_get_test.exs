defmodule Grizzly.ZWave.Commands.SecurityCommandsSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SecurityCommandsSupportedGet

  test "creates the command and validates params" do
    assert {:ok, _} = SecurityCommandsSupportedGet.new()
  end

  test "encodes params correctly" do
    assert {:ok, cmd} = SecurityCommandsSupportedGet.new()
    assert <<>> = SecurityCommandsSupportedGet.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, []} = SecurityCommandsSupportedGet.decode_params(<<>>)
  end
end
