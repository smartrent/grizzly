defmodule Grizzly.ZWave.Commands.BarrierOperatorReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.BarrierOperatorReport

  test "creates the command and validates params" do
    params = [state: :closed]
    {:ok, _command} = Commands.create(:barrier_operator_report, params)
  end

  describe "encodes params correctly" do
    test "completed state" do
      binary_params = <<0xFF>>
      {:ok, params} = BarrierOperatorReport.decode_params(binary_params)
      assert Keyword.get(params, :state) == :open
    end

    test "stopped state" do
      binary_params = <<0x10>>
      {:ok, params} = BarrierOperatorReport.decode_params(binary_params)
      assert Keyword.get(params, :state) == 0x10
    end
  end

  test "decodes params correctly" do
    binary_params = <<0x00>>
    {:ok, params} = BarrierOperatorReport.decode_params(binary_params)
    assert Keyword.get(params, :state) == :closed
  end
end
