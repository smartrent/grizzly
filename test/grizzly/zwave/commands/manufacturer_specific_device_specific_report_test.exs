defmodule Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ManufacturerSpecificDeviceSpecificReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, report} =
      ManufacturerSpecificDeviceSpecificReport.new(
        device_id_type: :serial_number,
        device_id: "h'30313233"
      )

    assert Command.param!(report, :device_id_type) == :serial_number
    assert Command.param!(report, :device_id) == "h'30313233"
  end

  test "encodes params correctly" do
    {:ok, report} =
      ManufacturerSpecificDeviceSpecificReport.new(
        device_id_type: :serial_number,
        device_id: "h'30313233"
      )

    expected_params_binary = <<
      # reserved
      0x00::size(5),
      # device id type
      0x01::size(3),
      # device id data format
      0x01::size(3),
      # device id data length
      0x04::size(5),
      # device id data
      0x30,
      0x31,
      0x32,
      0x33
    >>

    assert expected_params_binary ==
             ManufacturerSpecificDeviceSpecificReport.encode_params(report)
  end

  test "decodes params correctly" do
    params_binary = <<
      # reserved
      0x00::size(5),
      # device id type
      0x01::size(3),
      # device id data format
      0x01::size(3),
      # device id data length
      0x04::size(5),
      # device id data
      0x30,
      0x31,
      0x32,
      0x33
    >>

    {:ok, params} = ManufacturerSpecificDeviceSpecificReport.decode_params(params_binary)
    assert Keyword.get(params, :device_id_type) == :serial_number
    assert Keyword.get(params, :device_id) == "h'30313233"
  end
end
