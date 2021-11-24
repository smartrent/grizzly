defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BarrierOperatorSignalSet

  test "creates the command and validates params" do
    params = [subsystem_type: :audible_notification, subsystem_state: :on]
    {:ok, _command} = BarrierOperatorSignalSet.new(params)
  end

  test "encodes params correctly" do
    params = [subsystem_type: :audible_notification, subsystem_state: :on]
    {:ok, command} = BarrierOperatorSignalSet.new(params)
    expected_binary = <<0x01, 0xFF>>
    assert expected_binary == BarrierOperatorSignalSet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x00>>
    {:ok, params} = BarrierOperatorSignalSet.decode_params(binary_params)
    assert Keyword.get(params, :subsystem_type) == :visual_notification
    assert Keyword.get(params, :subsystem_state) == :off
  end
end
