defmodule Grizzly.ZWave.Commands.MultiChannelCapabilityGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.MultiChannelCapabilityGet

  test "creates the command and validates params" do
    params = [end_point: 1]
    {:ok, _command} = Commands.create(:multi_channel_capability_get, params)
  end

  test "encodes params correctly" do
    params = [end_point: 1]
    {:ok, command} = Commands.create(:multi_channel_capability_get, params)
    expected_binary = <<0x00::1, 0x01::7>>
    assert expected_binary == MultiChannelCapabilityGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    params_binary = <<0x00::1, 0x01::7>>
    {:ok, params} = MultiChannelCapabilityGet.decode_params(nil, params_binary)
    assert Keyword.get(params, :end_point) == 1
  end
end
