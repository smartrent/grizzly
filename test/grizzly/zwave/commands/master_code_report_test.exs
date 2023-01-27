defmodule Grizzly.ZWave.Commands.MasterCodeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MasterCodeReport

  test "creates the command and validates params" do
    assert {:ok, _command} = MasterCodeReport.new(code: "1234")
  end

  describe "encodes params correctly" do
    test "setting user code available" do
      {:ok, command} = MasterCodeReport.new(code: "0000")
      expected_binary = <<0x04, 0x30, 0x30, 0x30, 0x30>>
      assert expected_binary == MasterCodeReport.encode_params(command)
    end

    test "setting user code occupied" do
      {:ok, command} = MasterCodeReport.new(code: "12345")
      expected_binary = <<0x05, 0x31, 0x32, 0x33, 0x34, 0x35>>
      assert expected_binary == MasterCodeReport.encode_params(command)
    end
  end

  test "decodes params correctly" do
    binary = <<0x04, 0x34, 0x38, 0x32, 0x31>>
    {:ok, params} = MasterCodeReport.decode_params(binary)
    assert Keyword.get(params, :code) == "4821"
  end
end
