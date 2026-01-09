defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.PowerlevelTestNodeSet

  test "creates the command and validates params" do
    params = [test_node_id: 11, power_level: :minus1dBm, test_frame_count: 0xFF]
    {:ok, _command} = Commands.create(:powerlevel_test_node_set, params)
  end

  test "encodes params correctly" do
    params = [test_node_id: 11, power_level: :minus1dBm, test_frame_count: 0xFF]
    {:ok, command} = Commands.create(:powerlevel_test_node_set, params)
    expected_params_binary = <<0x0B, 0x01, 0xFF::16>>
    assert expected_params_binary == PowerlevelTestNodeSet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x0B, 0x01, 0xFF::16>>
    {:ok, params} = PowerlevelTestNodeSet.decode_params(params_binary)
    assert Keyword.get(params, :test_node_id) == 11
    assert Keyword.get(params, :power_level) == :minus1dBm
    assert Keyword.get(params, :test_frame_count) == 0xFF
  end
end
