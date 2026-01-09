defmodule Grizzly.ZWave.Commands.FirmwareUpdateActivationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.FirmwareUpdateActivationSet

  test "creates the command and validates params" do
    {:ok, command} =
      Commands.create(
        :firmware_update_activation_set,
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        hardware_version: 4
      )

    assert Command.param!(command, :manufacturer_id) == 1
    assert Command.param!(command, :firmware_id) == 2
    assert Command.param!(command, :checksum) == 3
    assert Command.param!(command, :firmware_target) == 0
    assert Command.param!(command, :hardware_version) == 4
  end

  test "encodes params correctly - v1" do
    {:ok, command} =
      Commands.create(
        :firmware_update_activation_set,
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00>>

    assert expected_param_binary == FirmwareUpdateActivationSet.encode_params(command)
  end

  test "encodes params correctly - v5" do
    {:ok, command} =
      Commands.create(
        :firmware_update_activation_set,
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        hardware_version: 4
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04>>

    assert expected_param_binary == FirmwareUpdateActivationSet.encode_params(command)
  end

  test "decodes params correctly v1" do
    params_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00>>
    {:ok, params} = FirmwareUpdateActivationSet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_target) == 0
  end

  test "decodes params correctly v5" do
    params_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04>>
    {:ok, params} = FirmwareUpdateActivationSet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_target) == 0
    assert Keyword.get(params, :hardware_version) == 4
  end
end
