defmodule Grizzly.ZWave.Commands.AlarmEventSupportedGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmEventSupportedGet

  test "creates the command and validates params" do
    params = [type: :access_control]
    {:ok, _command} = AlarmEventSupportedGet.new(params)
  end

  test "encodes params correctly" do
    params = [type: :access_control]
    {:ok, command} = AlarmEventSupportedGet.new(params)
    expected_params_binary = <<0x06>>
    assert expected_params_binary == AlarmEventSupportedGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x06>>
    {:ok, params} = AlarmEventSupportedGet.decode_params(params_binary)
    assert Keyword.get(params, :type) == :access_control
  end
end
