defmodule Grizzly.ZWave.Commands.UserCodeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserCodeReport

  test "creates the command and validates params" do
    assert {:ok, _command} =
             Commands.create(:user_code_report, user_id: 1, status: :available, user_code: "1234")
  end

  describe "encodes params correctly" do
    test "setting user code available" do
      {:ok, command} =
        Commands.create(:user_code_report,
          user_id: 9,
          user_id_status: :available,
          user_code: "0000"
        )

      expected_binary = <<0x09, 0x00, 0x30, 0x30, 0x30, 0x30>>

      assert expected_binary == UserCodeReport.encode_params(command)
    end

    test "setting user code occupied" do
      {:ok, command} =
        Commands.create(:user_code_report,
          user_id: 5,
          user_id_status: :occupied,
          user_code: "12345"
        )

      expected_binary = <<0x05, 0x01, 0x31, 0x32, 0x33, 0x34, 0x35>>

      assert expected_binary == UserCodeReport.encode_params(command)
    end
  end

  test "decodes params correctly" do
    binary = <<0x07, 0x01, 0x34, 0x38, 0x32, 0x31>>
    {:ok, params} = UserCodeReport.decode_params(binary)

    assert Keyword.get(params, :user_id) == 7
    assert Keyword.get(params, :user_id_status) == :occupied
    assert Keyword.get(params, :user_code) == "4821"
  end
end
