defmodule Grizzly do
  alias Grizzly.{Conn, Command, Node, Controller, Notifications}
  alias Grizzly.Conn.Config
  alias Grizzly.Client.DTLS

  @type seq_number :: 0..255

  @typedoc """
  A type the repersents things the have/can establish connections
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

  Given a connected thing, Conn, Node, or Controller for example, a command module, and
  opts to the command module send and process the command.

  See individual command modules for information about what options it takes.
  """
  @spec send_command(connected, command_module :: module, command_opts :: keyword) ::
          :ok | {:ok, any} | {:error, any}
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

  def send_command(%Node{conn: conn}, command_module, command_opts) do
    send_command(conn, command_module, command_opts)
  end

  @spec close_connection(Conn.t()) :: :ok
  def close_connection(%Conn{} = conn) do
    Conn.close(conn)
  end

  @doc """
  Get a node from the network
  """
  @spec get_node(Node.node_id()) :: {:ok, Node.t()} | {:error, :node_not_found}
  defdelegate get_node(node_id), to: Grizzly.Network

  @doc """
  Reset the Z-Wave Module to a clean state
  """
  @spec reset_controller() :: :ok | {:error, :network_busy}
  defdelegate reset_controller(), to: Grizzly.Network, as: :reset

  @doc """
  List the nodes on the Z-Wave network
  """
  @spec get_nodes() :: {:ok, [Node.t()]} | {:error, :unable_to_get_nodes}
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
  """
  @spec subscribe(Notifications.topic()) :: :ok | {:error, :already_subscribed}
  defdelegate subscribe(topic), to: Notifications
end
