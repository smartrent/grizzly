defmodule Grizzly.ZWave.NotificationsTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Notifications

  doctest Grizzly.ZWave.Notifications

  describe "decode_event_params/3 for access_control credential usage events" do
    test "credential_unlock_operation" do
      assert Notifications.decode_event_params(
               :access_control,
               :credential_unlock_operation,
               <<0, 33, 1, 1, 0, 4>>
             ) ==
               {:ok, [user_id: 33, credentials_used: [%{type: :pin_code, slot_id: 4}]]}
    end

    test "credential_lock_operation" do
      assert Notifications.decode_event_params(
               :access_control,
               :credential_lock_operation,
               <<0, 33, 1, 1, 0, 4>>
             ) ==
               {:ok, [user_id: 33, credentials_used: [%{type: :pin_code, slot_id: 4}]]}
    end

    test "non_access_credential_used" do
      assert Notifications.decode_event_params(
               :access_control,
               :non_access_credential_used,
               <<0, 33, 1, 1, 0, 4>>
             ) ==
               {:ok, [user_id: 33, credentials_used: [%{type: :pin_code, slot_id: 4}]]}
    end
  end

  describe "decode_event_params/3 for :lock_operation_with_user_code and :unlock_operation_with_user_code" do
    for event <- [:lock_operation_with_user_code, :unlock_operation_with_user_code] do
      test "#{event}: decodes an embedded ExtendedUserCodeReport" do
        params_binary =
          <<0x63, 0x0D, 1::8, 300::16, 1::8, 6::8, "873227"::binary, 301::16>>

        assert Notifications.decode_event_params(:access_control, unquote(event), params_binary) ==
                 {:ok, [user_id: 300, user_id_status: :occupied, user_code: "873227"]}
      end

      test "#{event}: falls back to a bare Extended User Code list" do
        params_binary = <<300::16, 1::8, 6::8, "873227"::binary, 301::16>>

        assert Notifications.decode_event_params(:access_control, unquote(event), params_binary) ==
                 {:ok, [user_id: 300, user_id_status: :occupied, user_code: "873227"]}
      end

      test "#{event}: falls back to a bare Extended User Code list without a next_user_id trailer" do
        params_binary = <<300::16, 1::8, 6::8, "873227"::binary>>

        assert Notifications.decode_event_params(:access_control, unquote(event), params_binary) ==
                 {:ok, [user_id: 300, user_id_status: :occupied, user_code: "873227"]}
      end

      test "#{event}: returns an empty list when the binary cannot be decoded" do
        assert Notifications.decode_event_params(:access_control, unquote(event), <<0xFF>>) ==
                 {:ok, []}
      end
    end
  end
end
