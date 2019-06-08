defmodule Grizzly.CommandClass.Mailbox.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.Mailbox

  describe "parsing a byte to mode" do
    test "disabled" do
      assert :disabled == Mailbox.mode_from_byte(0x00)
    end

    test "mailbox service enabled" do
      assert :mailbox_service_enabled == Mailbox.mode_from_byte(0x01)
    end

    test "mailbox proxy enabled" do
      assert :mailbox_proxy_enabled == Mailbox.mode_from_byte(0x02)
    end
  end
end
