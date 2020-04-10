defmodule Grizzly.Inclusions.InclusionRunner do
  @moduledoc false

  use GenServer

  alias Grizzly.{Inclusions, SeqNumber}
  alias Grizzly.Inclusions.InclusionRunner.Inclusion
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.ZWave.{Security, Command}

  @typedoc """
  At any given moment there can only be 1 `InclusionRunner` process going so
  this process is the name of this module.

  However, all the function in this module can take the pid of the process or
  the name to aid in the flexibility of the calling context.
  """
  @type t :: pid() | __MODULE__

  def child_spec(args) do
    # Don't restart the inclusion if there is a failure
    %{id: __MODULE__, start: {__MODULE__, :start_link, [args]}, restart: :temporary}
  end

  @spec start_link([Inclusions.opt()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    controller_id = Keyword.get(opts, :controller_id, 1)
    handler = Keyword.get(opts, :handler, self())

    GenServer.start_link(
      __MODULE__,
      [controller_id: controller_id, handler: handler],
      name: __MODULE__
    )
  end

  @spec seq_number(t()) :: Grizzly.seq_number()
  def seq_number(runner \\ __MODULE__) do
    GenServer.call(runner, :seq_number)
  end

  @spec add_node(t()) :: :ok
  def add_node(runner \\ __MODULE__) do
    GenServer.call(runner, :add_node)
  end

  @spec add_node_stop(t()) :: :ok
  def add_node_stop(runner \\ __MODULE__) do
    GenServer.call(runner, :add_node_stop)
  end

  @spec remove_node(t()) :: :ok
  def remove_node(runner \\ __MODULE__) do
    GenServer.call(runner, :remove_node)
  end

  @spec remove_node_stop(t()) :: :ok
  def remove_node_stop(runner \\ __MODULE__) do
    GenServer.call(runner, :remove_node_stop)
  end

  @spec grant_keys(t(), [Security.key()]) :: :ok
  def grant_keys(runner \\ __MODULE__, security_keys) do
    GenServer.call(runner, {:grant_keys, security_keys})
  end

  @spec set_dsk(t(), non_neg_integer()) :: :ok
  def set_dsk(runner \\ __MODULE__, dsk \\ 0) do
    GenServer.call(runner, {:set_dsk, dsk})
  end

  @spec stop(t()) :: :ok
  def stop(runner \\ __MODULE__) do
    GenServer.stop(runner, :normal)
  end

  @impl true
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    controller_id = Keyword.fetch!(opts, :controller_id)
    {:ok, _} = AsyncConnection.start_link(Keyword.fetch!(opts, :controller_id))
    {:ok, %Inclusion{handler: handler, controller_id: controller_id}}
  end

  @impl true
  def handle_call(:add_node, _from, inclusion) do
    seq_number = SeqNumber.get_and_inc()
    {command, new_inclusion} = Inclusion.next_command(inclusion, :node_adding, seq_number)

    {:ok, command_ref} =
      AsyncConnection.send_command(inclusion.controller_id, command, timeout: 120_000)

    {:reply, :ok, Inclusion.update_command_ref(new_inclusion, command_ref)}
  end

  def handle_call(:add_node_stop, _from, inclusion) do
    :ok = AsyncConnection.stop_command(inclusion.controller_id, inclusion.current_command_ref)
    seq_number = SeqNumber.get_and_inc()

    {next_command, new_inclusion} =
      Inclusion.next_command(inclusion, :node_adding_stop, seq_number)

    {:ok, command_ref} =
      AsyncConnection.send_command(inclusion.controller_id, next_command, timeout: 60_000)

    {:reply, :ok, Inclusion.update_command_ref(new_inclusion, command_ref)}
  end

  def handle_call(:remove_node, _from, inclusion) do
    seq_number = SeqNumber.get_and_inc()
    {command, new_inclusion} = Inclusion.next_command(inclusion, :node_removing, seq_number)

    {:ok, command_ref} =
      AsyncConnection.send_command(inclusion.controller_id, command, timeout: 120_000)

    {:reply, :ok, Inclusion.update_command_ref(new_inclusion, command_ref)}
  end

  def handle_call(:remove_node_stop, _from, inclusion) do
    :ok = AsyncConnection.stop_command(inclusion.controller_id, inclusion.current_command_ref)
    seq_number = SeqNumber.get_and_inc()
    {command, new_inclusion} = Inclusion.next_command(inclusion, :node_removing_stop, seq_number)

    {:ok, command_ref} =
      AsyncConnection.send_command(inclusion.controller_id, command, timeout: 60_000)

    {:reply, :ok, Inclusion.update_command_ref(new_inclusion, command_ref)}
  end

  def handle_call({:grant_keys, keys}, _from, inclusion) do
    # TODO check keys granted are valid?
    seq_number = SeqNumber.get_and_inc()

    {command, inclusion} =
      Inclusion.next_command(inclusion, :keys_granted, seq_number,
        csa: false,
        accept: true,
        granted_keys: keys
      )

    {:ok, command_ref} =
      AsyncConnection.send_command(inclusion.controller_id, command, timeout: 120_000)

    {:reply, :ok, Inclusion.update_command_ref(inclusion, command_ref)}
  end

  def handle_call({:set_dsk, dsk}, _from, inclusion) do
    seq_number = SeqNumber.get_and_inc()

    case Inclusion.next_command(inclusion, :dsk_set, seq_number, dsk: dsk) do
      {:error, _} = error ->
        {:reply, error, inclusion}

      {command, inclusion} ->
        :ok

        {:ok, command_ref} =
          AsyncConnection.send_command(inclusion.controller_id, command, timeout: 120_000)

        {:reply, :ok, Inclusion.update_command_ref(inclusion, command_ref)}
    end
  end

  @impl true
  def handle_info(
        {:grizzly, :send_command, {:ok, command}},
        inclusion
      ) do
    handle_incoming_command(command, inclusion)
  end

  def handle_info({:grizzly, :unhandled_command, command}, inclusion) do
    handle_incoming_command(command, inclusion)
  end

  @impl true
  def terminate(:normal, inclusion) do
    :ok = AsyncConnection.stop(inclusion.controller_id)

    :ok
  end

  defp get_command({:ok, command}), do: command
  defp get_command(command), do: command

  defp build_inclusion_opts_for_command(command) do
    case command.name do
      :node_add_dsk_report ->
        [dsk_input_length: Command.param!(command, :input_dsk_length)]

      _ ->
        []
    end
  end

  defp handle_incoming_command(command, inclusion) do
    command = get_command(command)
    opts = build_inclusion_opts_for_command(command)

    inclusion = Inclusion.handle_command(inclusion, command, opts)
    respond_to_handler(inclusion.handler, command)

    if inclusion.state == :complete do
      {:stop, :normal, inclusion}
    else
      {:noreply, inclusion}
    end
  end

  defp respond_to_handler(handler, command) when is_pid(handler) do
    send(handler, {:grizzly, :inclusion, command})
  end

  defp respond_to_handler(handler_module, command) do
    handler_module.handle_command(command)
  end
end
