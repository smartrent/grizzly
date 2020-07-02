defmodule Grizzly.ZWave.Commands.AlarmSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmSet

  test "creates the command and validates params" do
    params = [zwave_type: :home_security, status: :enabled]
    {:ok, _command} = AlarmSet.new(params)
  end

  test "encodes params correctly" do
    params = [zwave_type: :home_security, status: :enabled]
    {:ok, command} = AlarmSet.new(params)
    expected_binary = <<0x07, 0xFF>>
    assert expected_binary == AlarmSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x07, 0xFF>>
    {:ok, params} = AlarmSet.decode_params(binary_params)
    assert Keyword.get(params, :zwave_type) == :home_security
    assert Keyword.get(params, :status) == :enabled
  end
end
