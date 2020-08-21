defmodule Grizzly.ZWave.Commands.ConfigurationBulkReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationBulkReport

  test "creates the command and validates params" do
    params = [
      reports_to_follow: 1,
      default: false,
      handshake: true,
      size: 1,
      offset: 0,
      values: [1, 2, 3]
    ]

    {:ok, _command} = ConfigurationBulkReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      reports_to_follow: 1,
      default: false,
      handshake: true,
      size: 2,
      offset: 0,
      values: [1, 2, 3]
    ]

    {:ok, command} = ConfigurationBulkReport.new(params)

    expected_params_binary =
      <<0x00::size(16), 0x03, 0x01, 0x00::size(1), 0x01::size(1), 0x00::size(3), 0x02::size(3),
        0x01::size(16), 0x02::size(16), 0x03::size(16)>>

    assert expected_params_binary == ConfigurationBulkReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary =
      <<0x00::size(16), 0x03, 0x01, 0x00::size(1), 0x01::size(1), 0x00::size(3), 0x02::size(3),
        0x01::size(16), 0x02::size(16), 0x03::size(16)>>

    {:ok, params} = ConfigurationBulkReport.decode_params(params_binary)
    assert Keyword.get(params, :reports_to_follow) == 1
    assert Keyword.get(params, :default) == false
    assert Keyword.get(params, :handshake) == true
    assert Keyword.get(params, :size) == 2
    assert Keyword.get(params, :offset) == 0
    assert Enum.sort(Keyword.get(params, :values)) == Enum.sort([1, 2, 3])
  end
end
