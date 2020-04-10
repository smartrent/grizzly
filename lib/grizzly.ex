defmodule Grizzly do
  @moduledoc """
  Grizzly functions for controlling Z-Wave devices and the
  Z-Wave network.

  ## Sending commands to Z-Wave

  The most fundamental function in `Grizzly` is `Grizzly.send_command/3`.

  There are two ways of using this function.

  First, by passing in a node id for a node on the network:

  ```elixir
  Grizzly.send_command(10, Grizzly.CommandClass.SwitchBinary.Get)
  {:ok, :on}

  Grizzly.send_command(10, Grizzly.CommandClass.SwitchBinary.Set, value: :off)
  ```

  This is useful for short lived deterministic communication like `iex`
  and scripts. This is because there is the overhead of connecting and
  disconnecting to the node for each call.

  For long lived applications that have non-deterministic sending of
  messages (some type of automated commands) and user expectations on
  device action we recommend using this function by passing in a
  `Grizzly.Node`, `Grizzly.Conn`, or `Grizzly.Controller`.

  ```elixir
  {:ok, zw_node} = Grizzly.get_node(10)
  {:ok, zw_node} = Grizzly.Node.connect(zw_node)

  {:ok, :on} = Grizzly.send_command(zw_node, Grizzly.CommandClass.SwitchBinary.Get)
  :ok = Grizzly.send_command(zw_node, Grizzly.CommandClass.SwitchBinary.Set, value: :on)
  ```
  This is useful because we maintain a heart beat with the node and overhead
  of establishing the connection is removed from `send_command`.

  In order for the consumer of Grizzly to use this in a long running application they
  will need to hold on to a reference to the connected Z-Wave Node.

  To know more commands and their arguments see the modules under the
  `Grizzly.CommandClass` name space.

  ## Subscribing to Z-Wave messages

  `Grizzly` has a pubsub module (`Grizzly.Notifications`) which is used for
  sending or receiving notifications to and from `Grizzly`.

  You can subscribe to notifications using:

  ```elixir
  Grizzly.subscribe(topic)
  ```

  This will subscribe the calling process to the supplied topic. So, if you
  are using `iex` you can see received messages with `flush`, although it would
  be most useful from a `GenServer` where you can use `handle_info` to handle
  the notifications.

  The available topics are:

      :controller_connected,
      :connection_established,
      :unsolicited_message,
      :node_added,
      :node_removed,
      :node_updated

  You can also `Grizzly.Notifications` directly, where there are additional and
  more useful functions available.
  """
  alias Grizzly.{Conn, Command, Node, Controller, Notifications}
  alias Grizzly.Conn.Config
  alias Grizzly.Client.DTLS

  @type seq_number :: 0..255

  @typedoc """
  A type the represents things the have/can establish connections
  to the Z/IP network.
  1. `Conn.t` - A Connection struct
  2. `Grizzly.Controller` - The controller process, this is a global, started on
  application start process
  3. `Node.t` - This is a Z-Wave Node that has been connected to the network
  """
  @type connected :: Conn.t() | Controller | Node.t()

  @conn_opts [:owner]

  @spec config() :: Config.t()
  def config() do
    case Application.get_env(:grizzly, Grizzly.Controller) do
      nil ->
        Config.new(
          ip: {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 1},
          port: 41230,
          client: DTLS
        )

      opts ->
        Config.new(opts)
    end
  end

  @doc """
  Send a command to the Z-Wave device, first checking if in inclusion/exclusion state.

  See individual command modules for information about what options it takes.
  """
  @spec send_command(
          connected | Node.node_id(),
          command_module :: module,
          command_opts :: keyword
        ) ::
          :ok | {:ok, any} | {:ok, :queued, reference} | {:error, any}
  def send_command(connected, command_module, command_opts \\ [])

  def send_command(%Conn{} = conn, command_module, opts) do
    # an option in opts is either a command or connection option
    command_opts = Keyword.drop(opts, @conn_opts)
    conn_opts = opts -- command_opts

    with {:ok, command} <- Command.start(command_module, command_opts) do
      Conn.send_command(conn, command, conn_opts)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def send_command(Controller, command_module, command_opts) do
    send_command(Controller.conn(), command_module, command_opts)
  end

  def send_command(%Node{conn: nil, id: 1}, command_module, command_opts) do
    send_command(Controller, command_module, command_opts)
  end

  def send_command(%Node{conn: conn}, command_module, command_opts) do
    send_command(conn, command_module, command_opts)
  end

  def send_command(node_id, command_module, command_opts) when is_integer(node_id) do
    with {:ok, zw_node} <- Grizzly.get_node(node_id),
         {:ok, zw_node} <- Node.connect(zw_node) do
      response = send_command(zw_node, command_module, command_opts)
      :ok = Node.disconnect(zw_node)
      response
    else
      error -> error
    end
  end

  @doc """
  Close a connection
  """
  @spec close_connection(Conn.t()) :: :ok
  def close_connection(%Conn{} = conn) do
    Conn.close(conn)
  end

  @doc """
  Get a node from the network

  This does not make a DTLS connection to the `Node.t()`
  and if you want to connect to the node use `Grizzly.Node.connect/1`.
  """
  @spec get_node(Node.node_id()) :: {:ok, Node.t()} | {:error, any()}
  defdelegate get_node(node_id), to: Grizzly.Network

  @doc """
  Reset the Z-Wave Module to a clean state
  """
  @spec reset_controller() :: {:ok, atom()} | {:error, :network_busy}
  defdelegate reset_controller(), to: Grizzly.Network, as: :reset

  @doc """
  List the nodes on the Z-Wave network
  """
  @spec get_nodes() :: {:ok, [Node.t()]} | {:error, :unable_to_get_node_list}
  defdelegate get_nodes(), to: Grizzly.Network

  @doc """
  Check to see if the network is busy
  """
  @spec network_busy?() :: boolean()
  defdelegate network_busy?(), to: Grizzly.Network, as: :busy?

  @doc """
  Check to see if the network is ready
  """
  @spec network_ready?() :: boolean()
  defdelegate network_ready?(), to: Grizzly.Network, as: :ready?

  @doc """
  Put network in inclusion mode
  """
  @spec add_node([Grizzly.Inclusion.opt()]) ::
          :ok | {:error, {:invalid_option, Grizzly.Inclusion.invalid_opts_reason()}}
  defdelegate add_node(opts \\ []), to: Grizzly.Inclusion

  @doc """
  Put network in exclusion mode
  """
  @spec remove_node([Grizzly.Inclusion.opt()]) :: :ok
  defdelegate remove_node(opts \\ []), to: Grizzly.Inclusion

  @doc """
  Put network out of inclusion mode
  """
  @spec add_node_stop() :: :ok
  defdelegate add_node_stop(), to: Grizzly.Inclusion

  @doc """
  Put network out of exclusion mode
  """
  @spec remove_node() :: :ok
  defdelegate remove_node_stop(), to: Grizzly.Inclusion

  @doc """
  Whether the node's command class versions are known
  """
  @spec command_class_versions_known?(Node.t()) :: boolean
  defdelegate command_class_versions_known?(zw_node), to: Grizzly.Node

  @doc """
  Update the command class version of a node
  """
  @spec update_command_class_versions(Node.t()) :: Node.t()
  defdelegate update_command_class_versions(zw_node), to: Node

  @doc """
  Put the controller in learn mode for a few seconds
  """
  @spec start_learn_mode([Grizzly.Inclusion.opt()]) :: :ok
  defdelegate start_learn_mode(opts \\ []), to: Grizzly.Inclusion

  @doc """
  Get the version of a node's command class, if the node does not have a version for
  this command class this function will try to get it from the Z-Wave network.
  """
  @spec get_command_class_version(Node.t(), atom) ::
          {:ok, non_neg_integer} | {:error, atom}
  defdelegate get_command_class_version(node, command_class_name), to: Node

  @doc """
  Whether a node has a given command class
  """
  @spec has_command_class?(Node.t(), atom) :: boolean
  defdelegate has_command_class?(node, command_class_name), to: Node

  @doc """
  Whether a node is connected.
  """
  @spec connected?(Node.t()) :: boolean
  defdelegate connected?(node), to: Node

  @doc """
  Get the command classes supported by a node.
  """
  @spec command_class_names(Node.t()) :: [atom()]
  defdelegate command_class_names(node), to: Node

  @doc """
  Subscribe to notifications about a topic

  See `Grizzly.Notifications` for more information
  """
  @spec subscribe(Notifications.topic()) :: :ok | {:error, :already_subscribed}
  defdelegate subscribe(topic), to: Notifications
end
