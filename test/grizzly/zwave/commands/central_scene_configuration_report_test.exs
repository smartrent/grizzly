defmodule Grizzly.ZWave.Commands.CentralSceneConfigurationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.CentralSceneConfigurationReport

  test "creates the command and validates params" do
    params = [slow_refresh: true]
    {:ok, _command} = CentralSceneConfigurationReport.new(params)
  end

  test "encodes params correctly" do
    params = [slow_refresh: true]
    {:ok, command} = CentralSceneConfigurationReport.new(params)
    expected_params_binary = <<0x01::1, 0x00::7>>
    assert expected_params_binary == CentralSceneConfigurationReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x01::1, 0x00::7>>
    {:ok, params} = CentralSceneConfigurationReport.decode_params(params_binary)
    assert Keyword.get(params, :slow_refresh) == true
  end
end
