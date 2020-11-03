defmodule Grizzly.ZWave.Commands.PriorityRouteReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.PriorityRouteReport

  test "creates the command and validates params" do
    params = [node_id: 4, speed: :"100kbit/s", type: :last_working_route, repeaters: [5, 6]]
    {:ok, _command} = PriorityRouteReport.new(params)
  end

  test "encodes params correctly" do
    params = [node_id: 4, speed: :"100kbit/s", type: :last_working_route, repeaters: [5, 6]]
    {:ok, command} = PriorityRouteReport.new(params)
    expected_binary = <<0x04, 0x01, 0x05, 0x06, 0x00, 0x00, 0x03>>
    assert expected_binary == PriorityRouteReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x04, 0x01, 0x05, 0x06, 0x00, 0x00, 0x03>>
    {:ok, params} = PriorityRouteReport.decode_params(params_binary)
    assert Keyword.get(params, :node_id) == 4
    assert Keyword.get(params, :speed) == :"100kbit/s"
    assert Keyword.get(params, :type) == :last_working_route
    assert Keyword.get(params, :repeaters) == [5, 6]
  end
end
