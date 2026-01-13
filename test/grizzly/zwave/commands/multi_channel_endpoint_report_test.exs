defmodule Grizzly.ZWave.Commands.MultiChannelEndpointReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelEndpointReport

  test "creates the command and validates params" do
    params = [dynamic: false, identical: true, endpoints: 3]
    {:ok, _command} = Commands.create(:multi_channel_endpoint_report, params)
  end

  test "creates the command and validates params - v4" do
    params = [dynamic: false, identical: true, endpoints: 3, aggregated_endpoints: 2]
    {:ok, _command} = Commands.create(:multi_channel_endpoint_report, params)
  end

  test "encodes params correctly" do
    params = [dynamic: false, identical: true, endpoints: 3]
    {:ok, command} = Commands.create(:multi_channel_endpoint_report, params)

    expected_binary =
      <<0x00::1, 0x01::1, 0x00::6, 0x00::1, 0x03::7>>

    assert expected_binary == MultiChannelEndpointReport.encode_params(nil, command)
  end

  test "encodes params correctly - v4" do
    params = [dynamic: false, identical: true, endpoints: 3, aggregated_endpoints: 2]
    {:ok, command} = Commands.create(:multi_channel_endpoint_report, params)

    expected_binary =
      <<0x00::1, 0x01::1, 0x00::6, 0x00::1, 0x03::7, 0x00::1, 0x02::7>>

    assert expected_binary == MultiChannelEndpointReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::1, 0x01::1, 0x00::6, 0x00::1, 0x03::7>>
    {:ok, params} = MultiChannelEndpointReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :dynamic) == false
    assert Keyword.get(params, :identical) == true
    assert Keyword.get(params, :endpoints) == 3
    assert Keyword.get(params, :aggregated_endpoints) == 0
  end

  test "decodes params correctly - v4" do
    binary_params =
      <<0x00::1, 0x01::1, 0x00::6, 0x00::1, 0x03::7, 0x00::1, 0x02::7>>

    {:ok, params} = MultiChannelEndpointReport.decode_params(nil, binary_params)
    assert Keyword.get(params, :dynamic) == false
    assert Keyword.get(params, :identical) == true
    assert Keyword.get(params, :endpoints) == 3
    assert Keyword.get(params, :aggregated_endpoints) == 2
  end
end
