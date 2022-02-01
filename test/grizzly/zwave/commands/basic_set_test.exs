defmodule Grizzly.ZWave.Commands.BasicSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BasicSet

  test "creates the command and validates params" do
    params = [value: :off]
    {:ok, _command} = BasicSet.new(params)
  end

  test "encodes params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = BasicSet.decode_params(binary_params)
    assert Keyword.get(params, :value) == :on
  end

  test "decodes params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = BasicSet.decode_params(binary_params)
    assert Keyword.get(params, :value) == :on
    binary_params = <<0x01>>
    {:ok, params} = BasicSet.decode_params(binary_params)
    assert Keyword.get(params, :value) == :on
  end
end
