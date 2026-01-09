defmodule Grizzly.ZWave.Commands.CredentialSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CredentialSet

  test "encodes params correctly" do
    params = [
      user_id: 1,
      credential_type: :rfid,
      credential_slot: 2,
      operation_type: :add,
      credential_data: <<0x01, 0x02, 0x03>>
    ]

    assert {:ok, command} = Commands.create(:credential_set, params)

    assert CredentialSet.encode_params(command) == <<
             1::16,
             0x03,
             2::16,
             0x00,
             3,
             0x01,
             0x02,
             0x03
           >>

    params = [
      user_id: 1,
      credential_type: :password,
      credential_slot: 2,
      operation_type: :add,
      credential_data: "abc"
    ]

    assert {:ok, command} = Commands.create(:credential_set, params)

    assert CredentialSet.encode_params(command) == <<
             1::16,
             0x02,
             2::16,
             0x00,
             6,
             "abc"::utf16
           >>
  end

  test "decodes params correctly" do
    binary = <<
      1::16,
      0x03,
      2::16,
      0x00,
      3,
      0x01,
      0x02,
      0x03
    >>

    assert {:ok, params} = CredentialSet.decode_params(binary)

    assert params[:user_id] == 1
    assert params[:credential_type] == :rfid
    assert params[:credential_slot] == 2
    assert params[:operation_type] == :add
    assert params[:credential_data] == <<0x01, 0x02, 0x03>>

    binary = <<
      1::16,
      0x02,
      2::16,
      0x00,
      6,
      0,
      ?a,
      0,
      ?b,
      0,
      ?c
    >>

    assert {:ok, params} = CredentialSet.decode_params(binary)

    assert params[:user_id] == 1
    assert params[:credential_type] == :password
    assert params[:credential_slot] == 2
    assert params[:operation_type] == :add
    assert params[:credential_data] == "abc"
  end
end
