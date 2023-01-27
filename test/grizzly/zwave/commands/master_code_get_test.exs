defmodule Grizzly.ZWave.Commands.MasterCodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MasterCodeGet

  test "creates the command and validates params" do
    {:ok, _command} = MasterCodeGet.new([])
  end

  test "encodes params correctly" do
    {:ok, command} = MasterCodeGet.new([])
    assert <<>> == MasterCodeGet.encode_params(command)
  end

  test "decodes params correctly" do
    {:ok, params} = MasterCodeGet.decode_params(<<>>)
    assert params == []
  end
end
