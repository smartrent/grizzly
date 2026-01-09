defmodule Grizzly.ZWave.Commands.BarrierOperatorSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.BarrierOperatorSet

  test "creates the command and validates params" do
    params = [target_value: :close]
    {:ok, _command} = Commands.create(:barrier_operator_set, params)
  end

  test "encodes params correctly" do
    params = [target_value: :open]
    {:ok, command} = Commands.create(:barrier_operator_set, params)
    expected_binary = <<0xFF>>
    assert expected_binary == BarrierOperatorSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00>>
    {:ok, params} = BarrierOperatorSet.decode_params(binary_params)
    assert Keyword.get(params, :target_value) == :close
  end
end
