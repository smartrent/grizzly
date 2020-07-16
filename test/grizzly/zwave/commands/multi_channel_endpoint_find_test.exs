defmodule Grizzly.ZWave.Commands.MultiChannelEndpointFindTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MultiChannelEndpointFind

  test "creates the command and validates params" do
    params = [
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip
    ]

    {:ok, _command} = MultiChannelEndpointFind.new(params)
  end

  test "encodes params correctly" do
    params = [
      generic_device_class: :switch_binary,
      specific_device_class: :power_strip
    ]

    {:ok, command} = MultiChannelEndpointFind.new(params)
    expected_binary = <<0x10, 0x04>>
    assert expected_binary == MultiChannelEndpointFind.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x10, 0x04>>
    {:ok, params} = MultiChannelEndpointFind.decode_params(params_binary)
    assert Keyword.get(params, :generic_device_class) == :switch_binary
    assert Keyword.get(params, :specific_device_class) == :power_strip
  end
end
