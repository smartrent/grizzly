defmodule Grizzly.ZWave.Commands.ConfigurationInfoReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ConfigurationInfoReport

  test "creates the command and validates params" do
    params = [param_number: 2, info: "something", reports_to_follow: 0]
    {:ok, _command} = Commands.create(:configuration_info_report, params)
  end

  test "encodes params correctly" do
    params = [param_number: 2, info: "something", reports_to_follow: 0]
    {:ok, command} = Commands.create(:configuration_info_report, params)
    expected_params_binary = <<0x02::16, 0x00>> <> "something"
    assert expected_params_binary == ConfigurationInfoReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02::16, 0x00>> <> "something"
    {:ok, params} = ConfigurationInfoReport.decode_params(params_binary)
    assert Keyword.get(params, :param_number) == 2
    assert Keyword.get(params, :info) == "something"
  end
end
