defmodule Grizzly.ZWave.Commands.ConfigurationNameReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationNameReport

  test "creates the command and validates params" do
    params = [param_number: 2, name: "something"]
    {:ok, _command} = ConfigurationNameReport.new(params)
  end

  test "encodes params correctly" do
    params = [param_number: 2, name: "something"]
    {:ok, command} = ConfigurationNameReport.new(params)
    expected_params_binary = <<0x02::16, 0x00>> <> "something"
    assert expected_params_binary == ConfigurationNameReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x02::16, 0x00>> <> "something"
    {:ok, params} = ConfigurationNameReport.decode_params(params_binary)
    assert Keyword.get(params, :param_number) == 2
    assert Keyword.get(params, :name) == "something"
  end
end
