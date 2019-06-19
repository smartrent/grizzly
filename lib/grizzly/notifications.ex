defmodule Grizzly.Notifications do
  @moduledoc """
  A pubsub module for sending and receiving notifications to
  and from Grizzly.
  """

  require Logger

  @registry_name Registry.Grizzly

  @typedoc """
  The topics that are allowed for Grizzly notifications
  """
  @type topic ::
          :controller_connected
          | :connection_established
          | :network_ready
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
    _ = Logger.debug("BROADCASTING #{inspect(topic)} :: #{inspect(data)}")

    Registry.dispatch(@registry_name, topic, fn listeners ->
      for {pid, _} <- listeners, do: send(pid, {topic, data})
    end)
  end
end
