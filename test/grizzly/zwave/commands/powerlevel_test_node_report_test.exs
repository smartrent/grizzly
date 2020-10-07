defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PowerlevelTestNodeReport

  test "creates the command and validates params" do
    params = [test_node_id: 11, status_of_operation: :test_success, test_frame_count: 0xFF]
    {:ok, _command} = PowerlevelTestNodeReport.new(params)
  end

  test "encodes params correctly" do
    params = [test_node_id: 11, status_of_operation: :test_success, test_frame_count: 0xFF]
    {:ok, command} = PowerlevelTestNodeReport.new(params)
    expected_params_binary = <<0x0B, 0x01, 0xFF::size(16)>>
    assert expected_params_binary == PowerlevelTestNodeReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x0B, 0x01, 0xFF::size(16)>>
    {:ok, params} = PowerlevelTestNodeReport.decode_params(params_binary)
    assert Keyword.get(params, :test_node_id) == 11
    assert Keyword.get(params, :status_of_operation) == :test_success
    assert Keyword.get(params, :test_frame_count) == 0xFF
  end
end
