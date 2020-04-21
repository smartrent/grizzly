defmodule Grizzly.ZWave.Commands.ManufacturerSpecificReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ManufacturerSpecificReport

  test "creates the command and validates params" do
    {:ok, report} =
      ManufacturerSpecificReport.new(
        manufacturer_id: 0x01,
        product_id: 0x01,
        product_type_id: 0x01
      )

    assert Command.param!(report, :manufacturer_id) == 0x01
    assert Command.param!(report, :product_id) == 0x01
    assert Command.param!(report, :product_type_id) == 0x01
  end

  test "encodes params correctly" do
    {:ok, report} =
      ManufacturerSpecificReport.new(
        manufacturer_id: 0x01,
        product_id: 0x11,
        product_type_id: 0xFFFF
      )

    expected_param_binary = <<0x00, 0x01, 0xFF, 0xFF, 0x00, 0x11>>

    assert expected_param_binary == ManufacturerSpecificReport.encode_params(report)
  end

  test "decodes params correctly" do
    params_binary = <<0xFE, 0x01, 0xFF, 0x00, 0x00, 0x02>>
    {:ok, params} = ManufacturerSpecificReport.decode_params(params_binary)

    assert Keyword.get(params, :manufacturer_id) == 0xFE01
    assert Keyword.get(params, :product_id) == 0x02
    assert Keyword.get(params, :product_type_id) == 0xFF00
  end
end
