defmodule Grizzly.ZWave.Commands.S0CommandsSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.S0CommandsSupportedReport

  test "creates the command and validates params" do
    {:ok, _} =
      S0CommandsSupportedReport.new(supported: [:user_code], controlled: [:association])
  end

  test "encodes params correctly" do
    {:ok, cmd} =
      S0CommandsSupportedReport.new(
        supported: [:user_code],
        controlled: [:association],
        reports_to_follow: 15
      )

    bin = S0CommandsSupportedReport.encode_params(cmd)
    assert <<0xF, 0x63, 0xEF, 0x85>> = bin

    {:ok, cmd} = S0CommandsSupportedReport.new(supported: [:user_code])
    bin = S0CommandsSupportedReport.encode_params(cmd)
    assert <<0x0, 0x63, 0xEF>> = bin

    {:ok, cmd} = S0CommandsSupportedReport.new(controlled: [:user_code])
    bin = S0CommandsSupportedReport.encode_params(cmd)
    assert <<0x0, 0xEF, 0x63>> = bin
  end

  test "decodes params correctly" do
    {:ok, params} = S0CommandsSupportedReport.decode_params(<<0x0, 0x63, 0xEF, 0x85>>)
    assert 0 = params[:reports_to_follow]
    assert [:user_code] = params[:supported]
    assert [:association] = params[:controlled]

    {:ok, params} = S0CommandsSupportedReport.decode_params(<<0x1, 0x63, 0xEF>>)
    assert 1 = params[:reports_to_follow]
    assert [:user_code] = params[:supported]
    assert [] = params[:controlled]

    {:ok, params} = S0CommandsSupportedReport.decode_params(<<0xFF, 0x63, 0x85>>)
    assert 255 = params[:reports_to_follow]
    assert [:user_code, :association] = params[:supported]
    assert [] = params[:controlled]
  end
end
