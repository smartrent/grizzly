defmodule Grizzly.ZWave.Commands.S2CommandsSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.S2CommandsSupportedReport

  test "creates the command and validates params" do
    {:ok, _} =
      Commands.create(:s2_commands_supported_report, command_classes: [:user_code, :association])
  end

  test "encodes params correctly" do
    {:ok, cmd} =
      Commands.create(:s2_commands_supported_report, command_classes: [:user_code, :association])

    bin = S2CommandsSupportedReport.encode_params(cmd)
    assert <<0x63, 0x85>> = bin

    {:ok, cmd} = Commands.create(:s2_commands_supported_report, command_classes: [:user_code])
    bin = S2CommandsSupportedReport.encode_params(cmd)
    assert <<0x63>> = bin
  end

  test "decodes params correctly" do
    {:ok, params} = S2CommandsSupportedReport.decode_params(<<0x63, 0x85>>)
    assert [:user_code, :association] = params[:command_classes]

    {:ok, params} = S2CommandsSupportedReport.decode_params(<<0x63>>)
    assert [:user_code] = params[:command_classes]
  end
end
