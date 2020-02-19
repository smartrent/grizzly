defmodule Grizzly.Notifications do
  @moduledoc """
  A pubsub module for sending and receiving notifications to
  and from Grizzly.

  ## Subscribing to Z-Wave messages

  You can subscribe to notifications using:

  ```elixir
  Grizzly.Notifications.subscribe(topic)
  ```

  or

  ```elixir
  Grizzly.Notifications.subscribe_all([topic1, topic2])
  ```

  This will subscribe the calling process to the supplied topic(s). So, if you
  are using `iex` you can see received messages with `flush`, although it would
  be most useful from a `GenServer` where you can use `handle_info/2` to handle
  the notifications.

  The available topics are:

      :controller_connected,
      :connection_established,
      :unsolicited_message,
      :node_added,
      :node_removed,
      :node_updated

  You can unsubscribe with:

  ```elixir
  Grizzly.Notifications.unsubscribe(topic)
  ```

  """

  require Logger

  @registry_name Registry.Grizzly

  @typedoc """
  The topics that are allowed for Grizzly notifications
  """
  @type topic ::
          :controller_connected
          | :connection_established
          | :unsolicited_message
          | :node_added
          | :node_removed
          | :node_updated

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link() do
    _ = Logger.info("[GRIZZLY] Starting registry #{@registry_name}")
    Registry.start_link(keys: :duplicate, name: @registry_name)
  end

  @doc """
  Subscribe to a list of topics
  """
  @spec subscribe_all([topic]) :: :ok
  def subscribe_all(topics) do
    Enum.each(topics, &subscribe/1)
  end

  @doc """
  Subscribe to a topic to receive messages
  """
  @spec subscribe(topic) :: :ok | {:error, :already_subscribed}
  def subscribe(topic) do
    case Registry.register(@registry_name, topic, []) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :already_subscribed}
    end
  end

  @doc """
  Unsubscribe from a topic
  """
  @spec unsubscribe(topic) :: :ok
  def unsubscribe(topic) do
    Registry.unregister(@registry_name, topic)
  end

  @doc """
  Broadcast a `topic` to the processes that are subscribed
  """
  @spec broadcast(topic) :: :ok
  def broadcast(topic) do
    Registry.dispatch(@registry_name, topic, fn listeners ->
      for {pid, _} <- listeners, do: send(pid, topic)
    end)
  end

  @doc """
  Broadcast a `topic` and some `data` with the topic. This will send
  the subscriber a tuple in the shape of `{topic, data}`
  """
  @spec broadcast(topic, data :: any) :: :ok
  def broadcast(topic, data) do
    _ = Logger.debug("[GRIZZLY] BROADCASTING #{inspect(topic)} :: #{inspect(data)}")

    Registry.dispatch(@registry_name, topic, fn listeners ->
      for {pid, _} <- listeners, do: send(pid, {topic, data})
    end)
  end
end
