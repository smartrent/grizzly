defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDRequestGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.FirmwareUpdateMDRequestGet

  test "creates the command and validates params" do
    {:ok, command} =
      FirmwareUpdateMDRequestGet.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        fragment_size: 255,
        hardware_version: 2,
        activation_may_be_delayed: false
      )

    assert Command.param!(command, :manufacturer_id) == 1
    assert Command.param!(command, :firmware_id) == 2
    assert Command.param!(command, :checksum) == 3
    assert Command.param!(command, :fragment_size) == 255
    assert Command.param!(command, :hardware_version) == 2
    assert Command.param!(command, :activation_may_be_delayed) == false
  end

  test "encodes params correctly - v1" do
    {:ok, command} =
      FirmwareUpdateMDRequestGet.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03>>

    assert expected_param_binary == FirmwareUpdateMDRequestGet.encode_params(command)
  end

  test "encodes params correctly - v3" do
    {:ok, command} =
      FirmwareUpdateMDRequestGet.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        fragment_size: 255
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF>>

    assert expected_param_binary == FirmwareUpdateMDRequestGet.encode_params(command)
  end

  test "encodes params correctly - v4" do
    {:ok, command} =
      FirmwareUpdateMDRequestGet.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        fragment_size: 255,
        activation_may_be_delayed?: true
      )

    expected_param_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF, 0x00::7, 0x01::1>>

    assert expected_param_binary == FirmwareUpdateMDRequestGet.encode_params(command)
  end

  test "encodes params correctly - v5" do
    {:ok, command} =
      FirmwareUpdateMDRequestGet.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_target: 0,
        fragment_size: 255,
        hardware_version: 2,
        activation_may_be_delayed?: false
      )

    expected_param_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF, 0x00::7, 0x00::1, 0x02>>

    assert expected_param_binary == FirmwareUpdateMDRequestGet.encode_params(command)
  end

  test "decodes params correctly - v1" do
    params_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03>>

    {:ok, params} = FirmwareUpdateMDRequestGet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
  end

  test "decodes params correctly - v3" do
    params_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF>>

    {:ok, params} = FirmwareUpdateMDRequestGet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_target) == 0
    assert Keyword.get(params, :fragment_size) == 255
  end

  test "decodes params correctly - v4" do
    params_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF, 0x00::7, 0x01::1>>

    {:ok, params} = FirmwareUpdateMDRequestGet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_target) == 0
    assert Keyword.get(params, :fragment_size) == 255
    assert Keyword.get(params, :activation_may_be_delayed?) == true
  end

  test "decodes params correctly - v5" do
    params_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0xFF, 0x00::7, 0x00::1, 0x02>>

    {:ok, params} = FirmwareUpdateMDRequestGet.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_target) == 0
    assert Keyword.get(params, :fragment_size) == 255
    assert Keyword.get(params, :hardware_version) == 2
    assert Keyword.get(params, :activation_may_be_delayed?) == false
  end
end
