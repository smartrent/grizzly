defmodule Grizzly.ZWave.Commands.BarrierOperatorSignalGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BarrierOperatorSignalGet

  test "creates the command and validates params" do
    params = [subsystem_type: :audible_notification]
    {:ok, _command} = BarrierOperatorSignalGet.new(params)
  end

  test "encodes params correctly" do
    params = [subsystem_type: :audible_notification]
    {:ok, command} = BarrierOperatorSignalGet.new(params)
    expected_binary = <<0x01>>
    assert expected_binary == BarrierOperatorSignalGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = BarrierOperatorSignalGet.decode_params(binary_params)
    assert Keyword.get(params, :subsystem_type) == :visual_notification
  end
end
