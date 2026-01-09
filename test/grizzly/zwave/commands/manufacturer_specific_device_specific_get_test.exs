defmodule Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificGet

  test "creates the command and validates params" do
    params = [device_id_type: :serial_number]
    {:ok, _command} = Commands.create(:manufacturer_specific_device_specific_get, params)
  end

  test "encodes params correctly" do
    params = [device_id_type: :serial_number]
    {:ok, command} = Commands.create(:manufacturer_specific_device_specific_get, params)
    expected_binary = <<0x00::5, 0x01::3>>
    assert expected_binary == ManufacturerSpecificDeviceSpecificGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00::5, 0x01::3>>
    {:ok, params} = ManufacturerSpecificDeviceSpecificGet.decode_params(binary_params)
    assert Keyword.get(params, :device_id_type) == :serial_number
  end
end
