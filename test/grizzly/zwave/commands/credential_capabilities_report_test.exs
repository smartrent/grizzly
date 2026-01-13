defmodule Grizzly.ZWave.Commands.CredentialCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CredentialCapabilitiesReport

  test "encodes params correctly" do
    params = [
      credential_checksum_supported?: true,
      admin_code_supported?: false,
      admin_code_deactivation_supported?: true,
      credential_types: %{
        rfid: %{
          learn_supported?: true,
          supported_slots: 65535,
          min_length: 1,
          max_length: 50,
          recommended_learn_timeout: 101,
          learn_steps: 103,
          hash_max_length: 105
        },
        hand_biometric: %{
          learn_supported?: false,
          supported_slots: 128,
          min_length: 25,
          max_length: 100,
          recommended_learn_timeout: 102,
          learn_steps: 104,
          hash_max_length: 106
        }
      }
    ]

    assert {:ok, command} = Commands.create(:credential_capabilities_report, params)

    assert CredentialCapabilitiesReport.encode_params(nil, command) == <<
             0b10100000,
             2,
             # types
             0x03,
             0x0A,
             # learn supported
             0b10000000,
             0,
             # slots
             65535::16,
             128::16,
             # min length
             1,
             25,
             # max length
             50,
             100,
             # recommended learn timeout
             101,
             102,
             # learn steps
             103,
             104,
             # hash max length
             105,
             106
           >>
  end

  test "decodes params correctly" do
    encoded =
      <<
        0b10100000,
        2,
        # types
        0x03,
        0x0A,
        # learn supported
        0b10000000,
        0,
        # slots
        65535::16,
        128::16,
        # min length
        1,
        25,
        # max length
        50,
        100,
        # recommended learn timeout
        101,
        102,
        # learn steps
        103,
        104,
        # hash max length
        105,
        106
      >>

    assert {:ok, params} = CredentialCapabilitiesReport.decode_params(nil, encoded)
    assert params[:credential_checksum_supported?] == true
    assert params[:admin_code_supported?] == false
    assert params[:admin_code_deactivation_supported?] == true

    assert is_map(params[:credential_types])
    assert Enum.count(params[:credential_types]) == 2

    rfid_type = params[:credential_types][:rfid]
    assert rfid_type.learn_supported? == true
    assert rfid_type.supported_slots == 65535
    assert rfid_type.min_length == 1
    assert rfid_type.max_length == 50
    assert rfid_type.recommended_learn_timeout == 101
    assert rfid_type.learn_steps == 103
    assert rfid_type.hash_max_length == 105

    hand_biometric_type = params[:credential_types][:hand_biometric]
    assert hand_biometric_type.learn_supported? == false
    assert hand_biometric_type.supported_slots == 128
    assert hand_biometric_type.min_length == 25
    assert hand_biometric_type.max_length == 100
    assert hand_biometric_type.recommended_learn_timeout == 102
    assert hand_biometric_type.learn_steps == 104
    assert hand_biometric_type.hash_max_length == 106
  end
end
