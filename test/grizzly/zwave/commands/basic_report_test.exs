defmodule Grizzly.ZWave.Commands.BasicReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.BasicReport

  test "creates the command and validates params - v1" do
    params = [value: :off]
    {:ok, _command} = BasicReport.new(params)
  end

  test "creates the command and validates params - v2" do
    params = [value: :on, target_value: :off, duration: 10]
    {:ok, _command} = BasicReport.new(params)
  end

  test "encodes v1 params correctly" do
    params = [value: :on]
    {:ok, command} = BasicReport.new(params)
    expected_binary = <<0xFF>>
    assert expected_binary == BasicReport.encode_params(command)
  end

  test "encodes v2 params correctly" do
    params = [value: :on, target_value: :off, duration: 10]
    {:ok, command} = BasicReport.new(params)
    expected_binary = <<0xFF, 0x00, 0x0A>>
    assert expected_binary == BasicReport.encode_params(command)
  end

  test "decodes v1 params correctly" do
    binary_params = <<0xFF>>
    {:ok, params} = BasicReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == :on
  end

  test "decodes v2 params correctly" do
    binary_params = <<0xFE, 0x00, 0x81>>
    {:ok, params} = BasicReport.decode_params(binary_params)
    assert Keyword.get(params, :value) == :unknown
    assert Keyword.get(params, :target_value) == :off
    assert Keyword.get(params, :duration) == 120
  end
end
