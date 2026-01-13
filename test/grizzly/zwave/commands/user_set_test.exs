defmodule Grizzly.ZWave.Commands.UserSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserSet

  test "encodes params correctly" do
    params = [
      operation_type: :add,
      user_id: 1,
      user_type: :general,
      user_active?: true,
      credential_rule: :single,
      expiring_timeout_minutes: 60,
      username_encoding: :ascii,
      username: "test_user"
    ]

    assert {:ok, command} = Commands.create(:user_set, params)

    assert UserSet.encode_params(nil, command) == <<
             0b00000000,
             1::16,
             # general
             0x00,
             # active
             0b00000001,
             # single credential rule
             0x01,
             # expiring timeout
             60::16,
             # ascii encoding
             0x00,
             byte_size("test_user"),
             "test_user"
           >>

    params = [
      operation_type: :delete,
      user_id: 1024,
      user_type: :expiring,
      user_active?: false,
      credential_rule: :triple,
      expiring_timeout_minutes: 4096,
      username_encoding: :utf16,
      username: "test_user"
    ]

    assert {:ok, command} = Commands.create(:user_set, params)

    assert UserSet.encode_params(nil, command) == <<
             2,
             1024::16,
             # expiring
             0x07,
             # inactive
             0,
             # triple credential rule
             0x03,
             # expiring timeout
             4096::16,
             # utf16 encoding
             0x02,
             byte_size("test_user") * 2,
             "test_user"::utf16
           >>
  end

  test "decodes params correctly" do
    binary = <<
      0b00000000,
      1::16,
      0x00,
      1,
      0x01,
      60::16,
      0x00,
      byte_size("test_user"),
      "test_user"
    >>

    assert {:ok, params} = UserSet.decode_params(nil, binary)

    assert params[:operation_type] == :add
    assert params[:user_id] == 1
    assert params[:user_type] == :general
    assert params[:user_active?] == true
    assert params[:credential_rule] == :single
    assert params[:expiring_timeout_minutes] == 60
    assert params[:username_encoding] == :ascii
    assert params[:username] == "test_user"

    binary = <<
      2,
      1024::16,
      # expiring
      0x07,
      # inactive
      0,
      # triple credential rule
      0x03,
      # expiring timeout
      4096::16,
      # utf16 encoding
      0x02,
      byte_size("test_user") * 2,
      "test_user"::utf16
    >>

    assert {:ok, params} = UserSet.decode_params(nil, binary)

    assert params[:operation_type] == :delete
    assert params[:user_id] == 1024
    assert params[:user_type] == :expiring
    assert params[:user_active?] == false
    assert params[:credential_rule] == :triple
    assert params[:expiring_timeout_minutes] == 4096
    assert params[:username_encoding] == :utf16
    assert params[:username] == "test_user"
  end
end
