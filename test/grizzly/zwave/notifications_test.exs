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
end
