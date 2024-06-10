defmodule Grizzly.ZWave.Commands.FirmwareMDReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.FirmwareMDReport

  test "creates the command and validates params" do
    {:ok, report} =
      FirmwareMDReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3
      )

    assert Command.param!(report, :manufacturer_id) == 0x01
    assert Command.param!(report, :firmware_id) == 0x02
    assert Command.param!(report, :checksum) == 0x03
  end

  test "decodes params correctly - v1 " do
    params_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03>>
    {:ok, params} = FirmwareMDReport.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
  end

  test "decodes params correctly - v3 " do
    params_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06>>

    {:ok, params} = FirmwareMDReport.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_upgradable?)
    assert Keyword.get(params, :other_firmware_ids) == [5, 6]
    assert Keyword.get(params, :max_fragment_size) == 0x0A
  end

  test "decodes params correctly - v5 " do
    params_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06, 0x04>>

    {:ok, params} = FirmwareMDReport.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_upgradable?)
    assert Keyword.get(params, :other_firmware_ids) == [5, 6]
    assert Keyword.get(params, :max_fragment_size) == 10
    assert Keyword.get(params, :hardware_version) == 4
  end

  test "decodes params correctly - v6-7 " do
    params_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06, 0x04,
        0x00::6, 0x01::1, 0x00::1>>

    {:ok, params} = FirmwareMDReport.decode_params(params_binary)
    assert Keyword.get(params, :manufacturer_id) == 1
    assert Keyword.get(params, :firmware_id) == 2
    assert Keyword.get(params, :checksum) == 3
    assert Keyword.get(params, :firmware_upgradable?)
    assert Keyword.get(params, :other_firmware_ids) == [5, 6]
    assert Keyword.get(params, :max_fragment_size) == 10
    assert Keyword.get(params, :hardware_version) == 4
    assert Keyword.get(params, :activation_supported?)
    assert not Keyword.get(params, :active_during_transfer?)
  end

  test "encodes params correctly - v1" do
    {:ok, report} =
      FirmwareMDReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3
      )

    expected_param_binary = <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03>>
    assert expected_param_binary == FirmwareMDReport.encode_params(report)
  end

  test "encodes params correctly - v3" do
    {:ok, report} =
      FirmwareMDReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_upgradable?: true,
        max_fragment_size: 10,
        other_firmware_ids: [5, 6]
      )

    expected_param_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06>>

    assert expected_param_binary == FirmwareMDReport.encode_params(report)
  end

  test "encodes params correctly - v5" do
    {:ok, report} =
      FirmwareMDReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_upgradable?: true,
        max_fragment_size: 10,
        other_firmware_ids: [5, 6],
        hardware_version: 4
      )

    expected_param_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06, 0x04>>

    assert expected_param_binary == FirmwareMDReport.encode_params(report)
  end

  test "encodes params correctly - v6-7" do
    {:ok, report} =
      FirmwareMDReport.new(
        manufacturer_id: 1,
        firmware_id: 2,
        checksum: 3,
        firmware_upgradable?: true,
        max_fragment_size: 10,
        other_firmware_ids: [5, 6],
        hardware_version: 4,
        activation_supported?: true,
        active_during_transfer?: false
      )

    expected_param_binary =
      <<0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0xFF, 0x02, 0x00, 0x0A, 0x00, 0x05, 0x00, 0x06, 0x04,
        0x00::6, 0x01::1, 0x00::1>>

    assert expected_param_binary == FirmwareMDReport.encode_params(report)
  end
end
