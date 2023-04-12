defmodule Grizzly.ZWave.Commands.Security2CommandsSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.Security2CommandsSupportedReport

  test "creates the command and validates params" do
    {:ok, _} = Security2CommandsSupportedReport.new(command_classes: [:user_code, :association])
  end

  test "encodes params correctly" do
    {:ok, cmd} = Security2CommandsSupportedReport.new(command_classes: [:user_code, :association])
    bin = Security2CommandsSupportedReport.encode_params(cmd)
    assert <<0x63, 0x85>> = bin

    {:ok, cmd} = Security2CommandsSupportedReport.new(command_classes: [:user_code])
    bin = Security2CommandsSupportedReport.encode_params(cmd)
    assert <<0x63>> = bin
  end

  test "decodes params correctly" do
    {:ok, params} = Security2CommandsSupportedReport.decode_params(<<0x63, 0x85>>)
    assert [:user_code, :association] = params[:command_classes]

    {:ok, params} = Security2CommandsSupportedReport.decode_params(<<0x63>>)
    assert [:user_code] = params[:command_classes]
  end
end
