defmodule Grizzly.UnsolicitedServer.Socket.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.UnsolicitedServer.Socket

  test "prepare basic report messages" do
    packet = %Packet{
      body: %{
        command_class: :fake,
        value: :value
      }
    }

    expected_message = %{
      node_id: 1,
      command_class: :fake,
      value: :value
    }

    assert expected_message == Socket.prepare_message(packet, 1)
  end

  test "prepares message with different reporting packets" do
    packet = %Packet{
      body: %{
        command_class: :bar,
        some_other_field: :baz,
        another_field: :foo
      }
    }

    expected_message = %{
      node_id: 1,
      command_class: :bar,
      value: %{some_other_field: :baz, another_field: :foo}
    }

    assert expected_message == Socket.prepare_message(packet, 1)
  end
end
