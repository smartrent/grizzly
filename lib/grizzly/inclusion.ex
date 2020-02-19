defmodule Grizzly.Inclusion do
  @moduledoc """
  Z-Wave Inclusion Server

  ## Overview

  When using this process inclusion and exclusion are
  done asynchronously and information will be communicated
  via message passing.

  By default this process will send information about the
  inclusion to the process that started the inclusion. However,
  if you pass the `:client` option into the call that points to
  a `pid`, messages will be sent to that process.

  Move over, the caller can pass in the `:timeout` option in order to
  set the timeout of the inclusion. By default this is set to one minute.

  ## Adding Nodes

  ### Add

  To add a node to the network this is what will be called:

  ```elixir
  Grizzly.Inclusion.add_node()
  ```

  This will return `:ok` and set the Z-Wave module into add node mode.

  You can use `RingLogger.next` to see the logs from `grizzly` and
  `Grizzly` to verify. In this example, whatever messages that are sent
  will go to the process who called this function. If you have a process
  that you what to filter all inclusion messages through you can run this:

  ```elixir
  Grizzly.Inclusion.add_node(client: some_pid)
  ```
  This will then filter all messages to that client.

  A notification will be broadcasted, and a message sent to the client, like this:

  `{:node_added, %Grizzly.Node{}}`


  ### Remove

  To remove a node from the network this function should be called:

  ```elixir
  Grizzly.Inclusion.remove_node()
  ```
  The `:client` option works like adding a node.

  When removing a node is successful and complete, a notification will be broadcasted, and a message sent to the client, like this:

  `{:node_removed, node_id}`

  Where `node_id` is an integer of the node's id that was removed

  If the `node_id` is `0`, then the node was removed from another
  network and now can be included into this controller's network.

  ### Stopping

  This is useful for when an inclusion has started and the user wants to
  stop the inclusion process from taking place. The function to do this:

  ```elixir
  Grizzly.Inclusion.add_node_stop()
  ```

  When this takes places the client will be sent a message like this:

  `:node_add_stopped`

  This is the same for removing a node but instead run this function:

  ```elixir
  Grizzly.Inclusion.remove_node_stop()
  ```

  And this message will be sent to the client

  `:node_remove_stopped`

  ### Learn mode

  It is necessary to put the controller into Learn mode for it to be included by another controller.
  This is required for certification testing.

    ```elixir
  Grizzly.Inclusion.start_learn_mode()

  ```
  The `:client` option works like adding a node.

   When being in Learn mode completes, a message sent to the client, like this:

  `{:learn_mode_set, %{status: :done, new_node_id: 4}}`

  When `status` is :done, `new_node_id` is the new node id taken by the controller (an integer other than 0).

  When `status` is :failed or :security_failed, Learn mode completed without the controller being included.

  ## Timeouts

  By default the timeout is set to one minute, but the `:timeout`
  option can passed into to either `add_node/1` or `remove_node/1`
  in milliseconds to adjust the timeout.

  When the time passes for the timeout to trigger the client will
  be sent two messages. The first is to let the client know that
  it timed out and the second is to confirm that the inclusion
  process was stopped on the Z-Wave module.

  For when `add_node` was called, the messages look like:

  ```elixir
  {:timeout, :add_node}
  :node_add_stopped
  ```

  And for when `remove_node` was called, the messages look like:

  ```elixir
  {:timeout, :add_node}
  :node_add_stopped
  ```

  The controller will only stay in Learn mode for a limited amount of time. If the process times out before it completes
  (successfully or not), the Learn mode is aborted.

  ## Errors

  Errors are reported to the client as follows

  ```elixir
  {:error, :node_add_failed}
  {:error, :node_add_stopped}
  {:error, :node_remove_failed}
  {:error, :node_remove_stopped}
  {:error, :learn_mode_failed}
  {:error, :learn_mode_stopped}
  ```

  """
  use GenServer
  require Logger

  alias Grizzly.{SeqNumber, Notifications, Controller, Node, Security, Conn}

  alias Grizzly.CommandClass.NetworkManagementInclusion.{
    NodeAdd,
    NodeRemove,
    NodeAddKeysSet,
    NodeAddDSKSet
  }

  alias Grizzly.CommandClass.NetworkManagementBasic
  alias Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet

  @typedoc """
  Options for inclusion and exclusion process

  - `:client` - the process the messages from the inclusion will sent to (default `self`)
  - `:timeout` - the timeout interval for when to stop the adding/removing a node (default 60_000)
  - `:pin` - this is used for S2 authenticated, when doing S2 authenticated inclusion this should be the 5 digit number printed on the joining device.
  - `:s2_keys` - What keys to grant when the join node request keys, this will use the highest security group.
  """
  @type opt ::
          {:client, pid()}
          | {:timeout, non_neg_integer()}
          | {:pin, non_neg_integer | nil}
          | {:s2_keys, [Security.key()]}

  @type learn_mode_report :: %{
          status: NetworkManagementBasic.learn_mode_status(),
          new_node_id: non_neg_integer
        }

  @type invalid_opts_reason :: :pin_required_for_s2_authentication | :pin_size_invalid

  defmodule State do
    @moduledoc false
    alias Grizzly.Conn

    @type t :: %__MODULE__{
            conn: Conn.t() | nil,
            inclusion_opts: [Grizzly.Inclusion.opt()]
          }
    defstruct conn: nil,
              inclusion_opts: []
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start the process to add a node the network
  """
  @spec add_node([opt]) :: :ok | {:error, {:invalid_option, invalid_opts_reason}}
  def add_node(opts \\ []) do
    opts = setup_inclusion_opts(opts)

    case validate_options(opts) do
      :valid ->
        GenServer.cast(__MODULE__, {:add_node, opts})

      {:invalid_option, _reason} = error ->
        {:error, error}
    end
  end

  @doc """
  Stop the process to add a node to the network
  """
  @spec add_node_stop([opt]) :: :ok
  def add_node_stop(opts \\ [])

  def add_node_stop(opts) do
    opts = if opts == [], do: setup_inclusion_opts(opts), else: opts
    GenServer.cast(__MODULE__, {:add_node_stop, opts})
  end

  @doc """
  Remove a node from the network
  """
  @spec remove_node([opt]) :: :ok
  def remove_node(opts \\ []) do
    opts = setup_inclusion_opts(opts)
    GenServer.cast(__MODULE__, {:remove_node, opts})
  end

  @doc """
  Stop the remove node process from running
  """
  @spec remove_node_stop([opt]) :: :ok
  def remove_node_stop(opts \\ [])

  def remove_node_stop(opts) do
    opts = if opts == [], do: setup_inclusion_opts(opts), else: opts
    GenServer.cast(__MODULE__, {:remove_node_stop, opts})
  end

  @doc """
    Put the controller in learn mode for a few seconds
  """
  @spec start_learn_mode([opt]) :: :ok | {:error, {:invalid_option, invalid_opts_reason()}}
  def start_learn_mode(opts \\ []) do
    opts = setup_inclusion_opts(opts)

    case validate_options(opts) do
      :valid ->
        GenServer.cast(__MODULE__, {:learn_mode_start, opts})

      {:invalid_option, _reason} = error ->
        {:error, error}
    end
  end

  @doc """
    Put the controller out of learn mode
  """
  def stop_learn_mode(opts) do
    GenServer.cast(__MODULE__, {:learn_mode_stop, opts})
  end

  @impl true
  def init(_) do
    :ok = Notifications.subscribe(:controller_connected)
    {:ok, %State{}}
  end

  def handle_cast({:add_node, opts}, %State{conn: conn} = state) do
    seq_number = SeqNumber.get_and_inc()

    case Grizzly.send_command(
           conn,
           NodeAdd,
           seq_number: seq_number,
           exec_state: :including,
           timeout: Keyword.get(opts, :timeout)
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Add node failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :node_add_failed})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  @impl true
  def handle_cast(
        {:add_node_stop, opts},
        %State{conn: conn} = state
      ) do
    seq_number = SeqNumber.get_and_inc()
    # Cancel any busy network state before stopping inclusion
    case Grizzly.send_command(
           conn,
           NodeAdd,
           seq_number: seq_number,
           mode: :stop,
           pre_states: [:including],
           exec_state: :inclusion_stopping
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Add node stop failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :node_add_stopped})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  def handle_cast({:remove_node, opts}, %State{conn: conn} = state) do
    case Grizzly.send_command(
           conn,
           NodeRemove,
           seq_number: SeqNumber.get_and_inc(),
           exec_state: :excluding,
           timeout: Keyword.get(opts, :timeout)
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Remove node failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :node_remove_failed})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  def handle_cast(
        {:remove_node_stop, opts},
        %State{conn: conn} = state
      ) do
    seq_number = SeqNumber.get_and_inc()

    case Grizzly.send_command(
           conn,
           NodeRemove,
           seq_number: seq_number,
           mode: :stop,
           pre_states: [:excluding],
           exec_state: :exclusion_stopping
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Remove node stop failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :node_remove_stopped})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  def handle_cast({:learn_mode_start, opts}, %State{conn: conn} = state) do
    seq_number = SeqNumber.get_and_inc()

    case Grizzly.send_command(
           conn,
           LearnModeSet,
           seq_number: seq_number,
           mode: :enable,
           exec_state: :learning,
           timeout: Keyword.get(opts, :timeout)
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Learn mode set failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :learn_mode_failed})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  def handle_cast({:learn_mode_stop, opts}, %State{conn: conn} = state) do
    seq_number = SeqNumber.get_and_inc()
    _ = Logger.info("Disabling learn mode")

    case Grizzly.send_command(
           conn,
           LearnModeSet,
           seq_number: seq_number,
           mode: :disable,
           pre_states: [:learning]
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        _ = Logger.warn("Learn mode disable failed: #{inspect(reason)}")
        send_to_client(opts, {:error, :learn_mode_stopped})
    end

    {:noreply, %{state | inclusion_opts: opts}}
  end

  @impl true
  def handle_info(:controller_connected, %State{} = state) do
    # Checkout an async version of the controllers connection
    {:noreply, %{state | conn: Controller.conn(:async)}}
  end

  def handle_info({:timeout, command_module}, %State{inclusion_opts: opts} = state) do
    case command_module do
      NodeRemove ->
        send_to_client(opts, {:timeout, :remove_node})
        remove_node_stop(opts)

      NodeAdd ->
        send_to_client(opts, {:timeout, :add_node})
        add_node_stop(opts)

      LearnModeSet ->
        _ = Logger.warn("Setting learn mode timed out")
        stop_learn_mode(opts)
    end

    {:noreply, state}
  end

  def handle_info(
        {:async_command, {:ok, %Node{} = zw_node}},
        %State{inclusion_opts: inclusion_opts} = state
      ) do
    with {:ok, zw_node} <- Node.connect(zw_node),
         {:ok, zw_node} <-
           Node.add_lifeline_group(zw_node, network_state: :configurating_new_node) do
      Notifications.broadcast(:node_added, zw_node)
      send_to_client(inclusion_opts, {:node_added, zw_node})
    end

    {:noreply, reset_state(state)}
  end

  def handle_info(
        {:async_command, {:ok, :node_add_stopped}},
        %State{inclusion_opts: inclusion_opts} = state
      ) do
    send_to_client(inclusion_opts, :node_add_stopped)
    {:noreply, state}
  end

  def handle_info(
        {:async_command, {:ok, :node_remove_stopped}},
        %State{inclusion_opts: inclusion_opts} = state
      ) do
    send_to_client(inclusion_opts, :node_remove_stopped)
    {:noreply, state}
  end

  def handle_info(
        {:async_command, {:error, reason} = error},
        %State{inclusion_opts: inclusion_opts} = state
      ) do
    _ = Logger.warn("Error on #{reason}")
    send_to_client(inclusion_opts, error)
    {:noreply, reset_state(state)}
  end

  def handle_info(
        {
          :async_command,
          {:node_add_keys_report, %{csa?: false, requested_keys: _requested_keys}}
        },
        %State{inclusion_opts: inclusion_opts, conn: conn} = state
      ) do
    seq_number = SeqNumber.get_and_inc()
    keys_to_grant = Keyword.get(inclusion_opts, :s2_keys)

    :ok =
      Grizzly.send_command(
        conn,
        NodeAddKeysSet,
        seq_number: seq_number,
        granted_keys: keys_to_grant
      )

    send_to_client(inclusion_opts, :setting_s2_keys)
    {:noreply, state}
  end

  # This handle_info is for S2_unauthenticated devices
  def handle_info(
        {:async_command, {:dsk_report_info, %{dsk: _dsk, required_input_length: 0}}},
        %State{inclusion_opts: inclusion_opts, conn: conn} = state
      ) do
    seq_number = SeqNumber.get_and_inc()

    :ok = Grizzly.send_command(conn, NodeAddDSKSet, seq_number: seq_number, input_dsk_length: 0)

    send_to_client(inclusion_opts, :sending_dsk_input)
    {:noreply, state}
  end

  def handle_info(
        {:async_command, {:dsk_report_info, %{dsk: _dsk, required_input_length: 2}}},
        %State{inclusion_opts: inclusion_opts, conn: conn} = state
      ) do
    case Keyword.get(inclusion_opts, :pin) do
      nil ->
        send_to_client(inclusion_opts, :provide_S2_pin)

      pin ->
        _ = send_node_add_dsk_set(conn, pin)
        send_to_client(inclusion_opts, :sending_dsk_input)
    end

    {:noreply, state}
  end

  def handle_info(
        # weak signal
        {:async_command, {:ok, node_id}},
        %State{inclusion_opts: inclusion_opts} = state
      )
      when is_integer(node_id) do
    Notifications.broadcast(:node_removed, node_id)
    send_to_client(inclusion_opts, {:node_removed, node_id})
    {:noreply, reset_state(state)}
  end

  def handle_info(
        {:async_command, {:ok, %{status: _status} = status_report}},
        %State{inclusion_opts: inclusion_opts} = state
      ) do
    _ = Logger.info("Learning mode status report: #{inspect(status_report)}")
    send_to_client(inclusion_opts, {:learn_mode_set, status_report})
    {:noreply, state}
  end

  def handle_info(message, state) do
    _ = Logger.info("Unhandled inclusion process message: #{inspect(message)}")
    {:noreply, state}
  end

  defp setup_inclusion_opts(opts) do
    opts
    |> Keyword.put_new(:timeout, 60_000)
    |> Keyword.put_new(:client, self())
    |> Keyword.put_new(:s2_keys, [])
  end

  defp validate_options(options) do
    case Security.get_highest_level(options[:s2_keys]) do
      :s2_authenticated ->
        validate_pin_option(options[:pin])

      _ ->
        :valid
    end
  end

  defp validate_pin_option(nil), do: {:invalid_option, :pin_required_for_s2_authentication}

  defp validate_pin_option(pin) do
    case Security.validate_user_input_pin_length(pin) do
      :invalid -> {:invalid_option, :pin_size_invalid}
      :valid -> :valid
    end
  end

  defp send_to_client(opts, message) do
    client = Keyword.get(opts, :client)
    send(client, message)
  end

  defp reset_state(%State{} = state) do
    %{state | inclusion_opts: []}
  end

  defp send_node_add_dsk_set(conn, pin) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      conn,
      NodeAddDSKSet,
      seq_number: seq_number,
      input_dsk: pin,
      input_dsk_length: 2
    )
  end
end
