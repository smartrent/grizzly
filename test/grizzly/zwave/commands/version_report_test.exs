defmodule Grizzly.ZWave.Commands.VersionReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.VersionReport

  test "creates the command and validates params" do
    {:ok, report} =
      Commands.create(
        :version_report,
        library_type: :static_controller,
        protocol_version: "2.0",
        firmware_version: "3.1",
        hardware_version: 4,
        other_firmware_versions: ["4.0", "5.1"]
      )

    assert Command.param!(report, :library_type) == :static_controller
    assert Command.param!(report, :protocol_version) == "2.0"
    assert Command.param!(report, :firmware_version) == "3.1"
    assert Command.param!(report, :hardware_version) == 4
    assert Command.param!(report, :other_firmware_versions) == ["4.0", "5.1"]
  end

  test "encodes params correctly - v1" do
    {:ok, report} =
      Commands.create(
        :version_report,
        library_type: :static_controller,
        protocol_version: "2.0",
        firmware_version: "3.1"
      )

    expected_params_binary = <<
      # library type
      0x01,
      # protocol version
      0x02,
      # protocol sub version
      0x00,
      # firmware version
      0x03,
      # firmware sub version
      0x01
    >>

    assert expected_params_binary == VersionReport.encode_params(report)
  end

  test "encodes params correctly - v2" do
    {:ok, report} =
      Commands.create(
        :version_report,
        library_type: :static_controller,
        protocol_version: "2.0",
        firmware_version: "3.1",
        hardware_version: 4,
        other_firmware_versions: ["4.0", "5.1"]
      )

    expected_params_binary = <<
      # library type
      0x01,
      # protocol version
      0x02,
      # protocol sub version
      0x00,
      # firmware version
      0x03,
      # firmware sub version
      0x01,
      # hardware version
      0x04,
      # number of other firmware targets
      0x02,
      # other firmware versions
      0x04,
      0x00,
      0x05,
      0x01
    >>

    assert expected_params_binary == VersionReport.encode_params(report)
  end

  test "decodes params correctly - v1" do
    params_binary = <<
      # library type
      0x01,
      # protocol version
      0x02,
      # protocol sub version
      0x00,
      # firmware version
      0x03,
      # firmware sub version
      0x01
    >>

    {:ok, params} = VersionReport.decode_params(params_binary)
    assert Keyword.get(params, :library_type) == :static_controller
    assert Keyword.get(params, :protocol_version) == "2.0"
    assert Keyword.get(params, :firmware_version) == "3.1"
  end

  test "decodes params correctly - v2" do
    params_binary = <<
      # library type
      0x01,
      # protocol version
      0x02,
      # protocol sub version
      0x00,
      # firmware version
      0x03,
      # firmware sub version
      0x01,
      # hardware version
      0x04,
      # number of other firmware targets
      0x02,
      # other firmware versions
      0x04,
      0x00,
      0x05,
      0x01
    >>

    {:ok, params} = VersionReport.decode_params(params_binary)
    assert Keyword.get(params, :library_type) == :static_controller
    assert Keyword.get(params, :protocol_version) == "2.0"
    assert Keyword.get(params, :firmware_version) == "3.1"
    assert Keyword.get(params, :hardware_version) == 4
    assert Keyword.get(params, :other_firmware_versions) == ["4.0", "5.1"]
  end

  test "decodes params correctly - v3 - patch" do
    params_binary = <<
      # library type
      0x01,
      # protocol version
      0x02,
      # protocol sub version
      0x00,
      # firmware version
      0x03,
      # firmware sub version
      0x01,
      # hardware version
      0x04,
      # number of other firmware targets is 0 whereby it should be 2
      0x00,
      # other firmware versions
      0x04,
      0x00,
      0x05,
      0x01
    >>

    {:ok, params} = VersionReport.decode_params(params_binary)
    assert Keyword.get(params, :library_type) == :static_controller
    assert Keyword.get(params, :protocol_version) == "2.0"
    assert Keyword.get(params, :firmware_version) == "3.1"
    assert Keyword.get(params, :hardware_version) == 4
    assert Keyword.get(params, :other_firmware_versions) == ["4.0", "5.1"]
  end
end
