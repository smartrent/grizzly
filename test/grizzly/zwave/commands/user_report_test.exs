defmodule Grizzly.ZWave.Commands.UserReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserReport

  test "encodes params correctly" do
    params = [
      report_type: :added,
      next_user_id: 2,
      modifier_type: :zwave,
      modifier_node_id: 4096,
      user_id: 1,
      user_type: :general,
      user_active?: true,
      credential_rule: :single,
      expiring_timeout_minutes: 60,
      username_encoding: :ascii,
      username: "test_user"
    ]

    assert {:ok, command} = Commands.create(:user_report, params)

    assert UserReport.encode_params(command) == <<
             0,
             2::16,
             2,
             4096::16,
             1::16,
             0x00,
             0b00000001,
             0x01,
             60::16,
             0x00,
             byte_size("test_user"),
             "test_user"
           >>

    params = [
      report_type: :response_to_get,
      next_user_id: 4096,
      modifier_type: :unknown,
      modifier_node_id: 0,
      user_id: 1,
      user_type: :expiring,
      user_active?: false,
      credential_rule: :dual,
      expiring_timeout_minutes: 1024,
      username_encoding: :utf16,
      username: "test_user"
    ]

    assert {:ok, command} = Commands.create(:user_report, params)

    assert UserReport.encode_params(command) == <<
             4,
             4096::16,
             1,
             0::16,
             1::16,
             0x07,
             0,
             0x02,
             1024::16,
             0x02,
             byte_size("test_user") * 2,
             "test_user"::utf16
           >>
  end

  test "decodes params correctly" do
    binary = <<
      0,
      2::16,
      2,
      4096::16,
      1::16,
      0x00,
      0b00000001,
      0x01,
      60::16,
      0x00,
      byte_size("test_user"),
      "test_user"
    >>

    assert {:ok, params} = UserReport.decode_params(binary)

    assert params[:report_type] == :added
    assert params[:next_user_id] == 2
    assert params[:modifier_type] == :zwave
    assert params[:modifier_node_id] == 4096
    assert params[:user_id] == 1
    assert params[:user_type] == :general
    assert params[:user_active?] == true
    assert params[:credential_rule] == :single
    assert params[:expiring_timeout_minutes] == 60
    assert params[:username_encoding] == :ascii
    assert params[:username] == "test_user"

    binary = <<
      4,
      4096::16,
      1,
      0::16,
      1::16,
      0x07,
      0,
      0x02,
      1024::16,
      0x02,
      byte_size("test_user") * 2,
      "test_user"::utf16
    >>

    assert {:ok, params} = UserReport.decode_params(binary)

    assert params[:report_type] == :response_to_get
    assert params[:next_user_id] == 4096
    assert params[:modifier_type] == :unknown
    assert params[:modifier_node_id] == 0
    assert params[:user_id] == 1
    assert params[:user_type] == :expiring
    assert params[:user_active?] == false
    assert params[:credential_rule] == :dual
    assert params[:expiring_timeout_minutes] == 1024
    assert params[:username_encoding] == :utf16
    assert params[:username] == "test_user"
  end
end
