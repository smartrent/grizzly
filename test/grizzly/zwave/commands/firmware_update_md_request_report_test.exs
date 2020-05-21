defmodule Grizzly.ZWave.Commands.FirwmareUpdateMDRequestReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.FirwmareUpdateMDRequestReport
  alias Grizzly.ZWave.Command

  test "creates the command and validates params" do
    {:ok, command} = FirwmareUpdateMDRequestReport.new(status: :insufficient_battery_level)

    assert Command.param!(command, :status) == :insufficient_battery_level
  end

  test "encodes params correctly" do
    {:ok, command} = FirwmareUpdateMDRequestReport.new(status: :ok)
    expected_param_binary = <<FirwmareUpdateMDRequestReport.encode_status(:ok)>>
    assert expected_param_binary == FirwmareUpdateMDRequestReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0xFF>>
    {:ok, params} = FirwmareUpdateMDRequestReport.decode_params(params_binary)
    assert Keyword.get(params, :status) == :ok
  end
end
