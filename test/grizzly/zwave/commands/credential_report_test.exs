defmodule Grizzly.ZWave.Commands.CredentialReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CredentialReport

  test "encodes params correctly" do
    params = [
      report_type: :added,
      user_id: 1,
      credential_type: :password,
      credential_slot: 1,
      read_back_supported?: true,
      credential_data: "test_password",
      modifier_type: :zwave,
      modifier_node_id: 256,
      next_credential_type: :password,
      next_credential_slot: 2
    ]

    {:ok, command} = Commands.create(:credential_report, params)

    assert CredentialReport.encode_params(command) == <<
             0,
             1::16,
             2,
             1::16,
             0b10000000,
             byte_size("test_password") * 2,
             "test_password"::utf16,
             2,
             256::16,
             2,
             2::16
           >>

    params = [
      report_type: :wrong_user_id,
      user_id: 1024,
      credential_type: :pin_code,
      credential_slot: 16384,
      read_back_supported?: false,
      credential_data: "1234",
      modifier_type: :unknown,
      modifier_node_id: 0,
      next_credential_type: :password,
      next_credential_slot: 2
    ]

    {:ok, command} = Commands.create(:credential_report, params)

    assert CredentialReport.encode_params(command) == <<
             0x09,
             1024::16,
             1,
             16384::16,
             0,
             4,
             "1234"::binary,
             1,
             0::16,
             2,
             2::16
           >>
  end

  test "decodes params correctly" do
    binary = <<
      0,
      1::16,
      2,
      1::16,
      0b10000000,
      byte_size("test_password") * 2,
      "test_password"::utf16,
      2,
      256::16,
      2,
      2::16
    >>

    assert {:ok, params} = CredentialReport.decode_params(binary)

    assert params[:report_type] == :added
    assert params[:user_id] == 1
    assert params[:credential_type] == :password
    assert params[:credential_slot] == 1
    assert params[:read_back_supported?] == true
    assert params[:credential_data] == "test_password"
    assert params[:modifier_type] == :zwave
    assert params[:modifier_node_id] == 256
    assert params[:next_credential_type] == :password
    assert params[:next_credential_slot] == 2

    binary = <<
      0x09,
      1024::16,
      1,
      16384::16,
      0,
      4,
      "1234"::binary,
      1,
      0::16,
      2,
      2::16
    >>

    assert {:ok, params} = CredentialReport.decode_params(binary)

    assert params[:report_type] == :wrong_user_id
    assert params[:user_id] == 1024
    assert params[:credential_type] == :pin_code
    assert params[:credential_slot] == 16384
    assert params[:read_back_supported?] == false
    assert params[:credential_data] == "1234"
    assert params[:modifier_type] == :unknown
    assert params[:modifier_node_id] == 0
    assert params[:next_credential_type] == :password
    assert params[:next_credential_slot] == 2
  end
end
