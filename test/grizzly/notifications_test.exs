defmodule Grizzly.Notifications.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Notifications

  setup do
    Notifications.start_link()
    :ok
  end

  test "able to subscribe to a topic" do
    :ok = Notifications.subscribe(:controller_connected)
  end

  test "get messages from a subscribe topic" do
    :ok = Notifications.subscribe(:controller_connected)
    Notifications.broadcast(:controller_connected)
    assert_receive :controller_connected
  end

  test "unsubscribe from a topic" do
    :ok = Notifications.subscribe(:controller_connected)
    :ok = Notifications.unsubscribe(:controller_connected)

    Notifications.broadcast(:controller_connected)

    refute_receive :controller_connected
  end

  test "subscribe to many topics at once" do
    :ok = Notifications.subscribe_all([:controller_connected, :node_removed])

    Notifications.broadcast(:controller_connected)

    assert_receive :controller_connected

    Notifications.broadcast(:node_removed)
  end
end
