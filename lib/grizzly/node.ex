defmodule Grizzly.Node do
  @moduledoc """
  Data structure representing a Z-Wave Node
  """

  require Logger
  alias Grizzly.{Conn, SeqNumber, Controller, CommandClass}
  alias Grizzly.Conn.Config
  alias Grizzly.Network.State, as: NetworkState
  alias Grizzly.Node.Association
  alias Grizzly.CommandClass.Association.Set, as: AssociationSet
  alias Grizzly.CommandClass.ZipNd.InvNodeSolicitation
  alias Grizzly.CommandClass.CommandClassVersion

  @type node_id :: non_neg_integer()

  @type association_opt :: {:network_state, NetworkState.state()} | {:extra_nodes, [node_id]}

  @type security :: :none | :failed | :s0 | :s2_unauthenticated | :s2_authenticated

  @type t :: %__MODULE__{
          id: node_id(),
          command_classes: [CommandClass.t()],
          security: security(),
          basic_cmd_class: atom() | nil,
          generic_cmd_class: atom() | nil,
          specific_cmd_class: atom() | nil,
          ip_address: :inet.ip_address() | nil,
          conn: Conn.t() | nil,
          associations: [Association.t()],
          listening?: boolean(),
          security: security()
        }

  @enforce_keys [:id]
  defstruct id: nil,
            command_classes: [],
            security: :none,
            basic_cmd_class: nil,
            generic_cmd_class: nil,
            specific_cmd_class: nil,
            ip_address: nil,
            associations: [],
            conn: nil,
            listening?: false,
            security: :none

  @spec new(opts :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Batch update a Node's fields with new info.
  """
  @spec update(t, opts :: keyword() | map()) :: t
  def update(zw_node, opts \\ []) do
    struct(zw_node, opts)
  end

  @doc """
  Adds the IP address to the node structure. If
  there is an IP address already part of the
  node this will override that field.
  """
  @spec put_ip(t, :inet.ip_address()) :: t
  def put_ip(zw_node, ip_address) do
    %{zw_node | ip_address: ip_address}
  end

  @doc """
  Get the Node's IP adress.

  If the node does not have an IP address this function
  will ask the Z-Wave network to provide the address.
  Normally, it is good to called `put_ip/2` after this
  function.

  If the node has the IP address already, then this
  function will return that address
  """
  @spec get_ip(t() | node_id()) :: {:ok, :inet.ip_address()} | {:error, :nack_response}
  def get_ip(%__MODULE__{ip_address: nil, id: node_id}) do
    do_get_ip(node_id)
  end

  def get_ip(%__MODULE__{ip_address: ip_address}), do: {:ok, ip_address}

  def get_ip(node_id) when is_integer(node_id) do
    do_get_ip(node_id)
  end

  @doc """
  Establish a connection with a Node

  Pass in connection options to build a `Grizzly.Conn`, will use
  `Grizzly.conn()` to build default values.

  If the node does not have an IP address, this function will attempt to
  retrieve that information from the Z-Wave network
  """
  @spec connect(t, keyword) :: {:ok, t}
  def connect(zw_node, opts \\ [])

  def connect(%__MODULE__{ip_address: nil} = zw_node, opts) do
    with {:ok, ip} <- get_ip(zw_node),
         zw_node <- put_ip(zw_node, ip) do
      connect(zw_node, opts)
    end
  end

  def connect(zw_node, opts) do
    config = make_config(zw_node, opts)
    conn = Conn.open(config)
    {:ok, %{initialize_command_versions(zw_node) | conn: conn}}
  end

  @spec disconnect(t) :: :ok
  def disconnect(%__MODULE__{conn: conn}) do
    Conn.close(conn)
  end

  @doc """
  Make the Node's Conn.Config. This will use the `Grizzly.config()` function
  but it will replace the ip_address field of that config with the Node's
  IP address.

  And optional keyword list of config overrides can be provided. See
  `Grizzly.Conn.Config` module for the valid fields.
  """
  @spec make_config(t, opts :: keyword) :: Config.t()
  def make_config(%__MODULE__{ip_address: ip_address}, opts \\ []) do
    struct(Grizzly.config(), [ip: ip_address] ++ opts)
  end

  @doc """
  Checks to see if the node has a particular command class
  """
  @spec has_command_class?(t, command_class :: atom) :: boolean
  def has_command_class?(%__MODULE__{} = zw_node, command_class) do
    command_class in command_class_names(zw_node)
  end

  @doc """
    Whether a node is connected
  """
  @spec connected?(t) :: boolean
  def connected?(%__MODULE__{conn: conn, ip_address: ip_address}) do
    conn != nil and ip_address != nil
  end

  @doc """
    Get the list of names of command classes supported by the node.
  """
  @spec command_class_names(t) :: [atom]
  def command_class_names(%__MODULE__{command_classes: command_classes}) do
    Enum.map(command_classes, fn %CommandClass{name: command_class_name} -> command_class_name end)
  end

  @doc """
    Get the node's command class by name
  """
  @spec command_class(t, atom) :: {:ok, CommandClass.t()} | {:error, :not_found}
  def command_class(node, command_class_name) do
    case Enum.find(node.command_classes, &(&1.name == command_class_name)) do
      nil ->
        {:error, :not_found}

      command_class ->
        {:ok, command_class}
    end
  end

  @doc """
  Update the command class versions of a node
  """
  @spec update_command_class_versions(t) :: t()
  def update_command_class_versions(%__MODULE__{command_classes: command_classes} = zw_node) do
    command_classes =
      Enum.map(command_classes, fn command_class ->
        command_class_name = CommandClass.name(command_class)

        case get_command_class_version(zw_node, command_class_name) do
          {:ok, version} ->
            CommandClass.set_version(command_class, version)

          {:error, :timeout_get_command_class_version} ->
            _ =
              Logger.warn(
                "Timeout getting the command class version of #{inspect(command_class_name)} for node #{
                  inspect(zw_node.id)
                }"
              )

            command_class

          {:error, :command_class_not_found} ->
            _ =
              Logger.warn(
                "Unable to get command command class for #{inspect(command_class_name)} because the node (#{
                  inspect(zw_node.id)
                }) does not support that command class"
              )

            command_class
        end
      end)

    %{zw_node | command_classes: command_classes}
  end

  @doc """
  Get the version of a node's command class, if the node does not have a version for
  this command class this function will try to get it from the Z-Wave network.
  """
  @spec get_command_class_version(t(), CommandClass.name()) ::
          {:ok, CommandClass.version()}
          | {:error, :command_class_not_found | :timeout_get_command_class_version}
  def get_command_class_version(zw_node, command_class_name) do
    with {:ok, cc} <- command_class(zw_node, command_class_name),
         :no_version_number <- CommandClass.version(cc),
         {:ok, %{version: version}} <- do_get_command_class_version(zw_node, command_class_name) do
      {:ok, version}
    else
      {:error, :not_found} ->
        {:error, :command_class_not_found}

      {:error, :timeout_get_command_class_version} = error ->
        error

      version when is_integer(version) ->
        {:ok, version}

      error ->
        # This should nerve happen, and if it does something is
        # really wrong in the system.
        raise "Unmatch error when getting a command class version #{inspect(error)}"
    end
  end

  @doc "Whether the versions of a node's command class are all known"
  @spec command_class_versions_known?(t) :: boolean
  def command_class_versions_known?(zw_node) do
    not Enum.any?(
      zw_node.command_classes,
      &(&1.version == :no_version_number)
    )
  end

  @doc """
    Update a command class of a node.
  """
  @spec update_command_class(t, CommandClass.t()) :: t
  def update_command_class(
        %__MODULE__{command_classes: command_classes} = zw_node,
        command_class
      ) do
    index = Enum.find_index(command_classes, &(&1.name == command_class.name))
    updated_command_classes = List.replace_at(command_classes, index, command_class)
    %__MODULE__{zw_node | command_classes: updated_command_classes}
  end

  @doc """
  Put an Association into the association list of a node.
  """
  @spec put_association(t, Association.t()) :: t
  def put_association(%__MODULE__{associations: associations} = zw_node, association) do
    %{zw_node | associations: associations ++ [association]}
  end

  @doc """
  Gets the association list of a Node.t
  """
  @spec get_association_list(t) :: [Association.t()]
  def get_association_list(%__MODULE__{associations: associations}), do: associations

  @doc """
  Add a lifeline group association to this node.

  By default the lifeline group contains the controller node (id `1`),
  so the `extra_nodes` field is a list of node ids to also be added
  to this node's lifeline group.
  """
  @spec add_lifeline_group(t, [association_opt]) :: {:ok, t}
  def add_lifeline_group(zw_node, association_opts \\ []) do
    extra_nodes = Keyword.get(association_opts, :extra_nodes, [])
    lifeline_association = Association.new(0x01, [0x01] ++ extra_nodes)
    configure_association(zw_node, lifeline_association, association_opts)
  end

  @doc """
  Given a Node and an Association configure the node to have association.
  """
  @spec configure_association(t, Association.t(), [association_opt]) :: {:ok, t}
  def configure_association(zw_node, association, association_opts \\ []) do
    # TODO: clean up
    _ = Logger.debug("CONFIGURING ASSOCIATION of node #{zw_node.id}")
    # Don't associate devices that may be a sleep (else the command times out)
    if has_command_class?(zw_node, :association) do
      seq_number = SeqNumber.get_and_inc()
      netstate = Keyword.get(association_opts, :network_state)

      cmd_opts =
        association
        |> Association.to_keyword()
        |> Keyword.put(:seq_number, seq_number)
        |> Keyword.put(:exec_state, netstate)

      case Grizzly.send_command(zw_node.conn, AssociationSet, cmd_opts) do
        :ok ->
          _ = Logger.debug("CONFIGURED association of node #{zw_node.id}")
          {:ok, put_association(zw_node, association)}

        {:error, reason} ->
          _ =
            Logger.warn(
              "Unable to set association for node #{zw_node.id} because #{inspect(reason)}"
            )

          {:ok, zw_node}
      end
    else
      {:ok, zw_node}
    end
  end

  @doc """
  Initialize a node's command classes with the default version
  """
  @spec initialize_command_versions(t()) :: t()
  def initialize_command_versions(%__MODULE__{command_classes: command_classes} = zw_node) do
    versioned_command_classes = Enum.map(command_classes, &initialize_command_class_version(&1))
    %__MODULE__{zw_node | command_classes: versioned_command_classes}
  end

  defp initialize_command_class_version(command_class_name) when is_atom(command_class_name) do
    CommandClass.new(name: command_class_name)
  end

  defp initialize_command_class_version(%CommandClass{} = command_class) do
    command_class
  end

  defp do_get_ip(node_id) do
    seq_number = SeqNumber.get_and_inc()

    command_result =
      Grizzly.send_command(
        Controller.conn(),
        InvNodeSolicitation,
        seq_number: seq_number,
        node_id: node_id
      )

    case command_result do
      {:ok, {:node_ip, _, ip_address}} ->
        {:ok, ip_address}

      {:error, _} = error ->
        error
    end
  end

  defp do_get_command_class_version(zw_node, command_class_name) do
    task =
      Task.async(fn ->
        seq_number = SeqNumber.get_and_inc()

        Grizzly.send_command(
          zw_node,
          CommandClassVersion.Get,
          seq_number: seq_number,
          command_class: command_class_name
        )
      end)

    try do
      # wait 5 secs
      Task.await(task)
    catch
      :exit, error ->
        # Task needs to be killed explicitly because we are trapping exits
        _ = Task.shutdown(task, :brutal_kill)

        _ =
          Logger.error(
            "[GRIZZLY] Exit trapped when getting version of command class #{command_class_name} of node #{
              zw_node.id
            }: #{inspect(error)}"
          )

        {:error, :timeout_get_command_class_version}
    end
  end
end
