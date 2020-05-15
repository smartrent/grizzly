defmodule Grizzly.ZWave.Commands.NodeProvisioningGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.NodeProvisioningGet

  test "creates the command and validates params" do
    params = [seq_number: 0x01, dsk: "50285-18819-09924-30691-15973-33711-04005-03623"]
    {:ok, _command} = NodeProvisioningGet.new(params)
  end

  test "encodes params correctly" do
    params = [seq_number: 0x01, dsk: "50285-18819-09924-30691-15973-33711-04005-03623"]
    {:ok, command} = NodeProvisioningGet.new(params)

    expected_binary =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    assert expected_binary == NodeProvisioningGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x01, 0x10, 196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>

    {:ok, params} = NodeProvisioningGet.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 1
    assert Keyword.get(params, :dsk) == "50285-18819-09924-30691-15973-33711-04005-03623"
  end
end
