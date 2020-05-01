defmodule Grizzly.ZWave.Commands.VersionReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.VersionReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, report} =
      VersionReport.new(
        library_type: :static_controller,
        protocol_version: "2.0",
        firmware_version: "3.1"
      )

    assert Command.param!(report, :library_type) == :static_controller
    assert Command.param!(report, :protocol_version) == "2.0"
    assert Command.param!(report, :firmware_version) == "3.1"
  end

  test "encodes params correctly" do
    {:ok, report} =
      VersionReport.new(
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

  test "decodes params correctly" do
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
end
