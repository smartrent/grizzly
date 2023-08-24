defmodule Grizzly.ZWave.Commands.AdminCodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AdminCodeGet

  test "creates the command and validates params" do
    {:ok, _command} = AdminCodeGet.new([])
  end

  test "encodes params correctly" do
    {:ok, command} = AdminCodeGet.new([])
    assert <<>> == AdminCodeGet.encode_params(command)
  end

  test "decodes params correctly" do
    {:ok, params} = AdminCodeGet.decode_params(<<>>)
    assert params == []
  end
end
