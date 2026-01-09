defmodule Grizzly.ZWave.Commands.SupervisionReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.SupervisionReport

  test "creates the command and validates params" do
    params = [more_status_updates: :last_report, session_id: 1, status: :working, duration: 180]
    {:ok, _command} = Commands.create(:supervision_report, params)
  end

  test "encodes params correctly" do
    params = [more_status_updates: :last_report, session_id: 1, status: :working, duration: 180]
    {:ok, command} = Commands.create(:supervision_report, params)

    expected_binary = <<0x01, 0x01, 0x82>>

    assert expected_binary == SupervisionReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01::1, 0x00::1, 0x01::6, 0x01, 0x0A>>

    {:ok, params} = SupervisionReport.decode_params(binary_params)
    assert Keyword.get(params, :more_status_updates) == :more_reports
    assert Keyword.get(params, :session_id) == 1
    assert Keyword.get(params, :status) == :working
    assert Keyword.get(params, :duration) == 10
  end
end
