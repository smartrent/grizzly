defmodule Grizzly.ZWave.Commands.UserCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserCapabilitiesReport

  test "encodes params correctly" do
    params = [
      max_users: 100,
      supported_credential_rules: [:single, :dual],
      username_max_length: 10,
      user_schedule_supported?: true,
      all_users_checksum_supported?: false,
      user_checksum_supported?: true,
      supported_username_encoding: [:utf16, :ascii],
      supported_user_types: [:general, :programming, :remote_only]
    ]

    {:ok, command} = Commands.create(:user_capabilities_report, params)
    encoded_params = UserCapabilitiesReport.encode_params(nil, command)

    assert <<100::16, 0b00000110, 10, 0b10110100, 2, 0b00001001, 0b10>> = encoded_params
  end

  test "decodes params correctly" do
    encoded_params = <<100::16, 0b00000110, 10, 0b10110100, 2, 0b00001001, 0b10>>

    {:ok, params} = UserCapabilitiesReport.decode_params(nil, encoded_params)

    assert params == [
             max_users: 100,
             supported_credential_rules: [:single, :dual],
             username_max_length: 10,
             user_schedule_supported?: true,
             all_users_checksum_supported?: false,
             user_checksum_supported?: true,
             supported_username_encoding: [:utf16, :ascii],
             supported_user_types: [:general, :programming, :remote_only]
           ]
  end
end
