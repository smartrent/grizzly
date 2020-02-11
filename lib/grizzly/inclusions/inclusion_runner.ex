defmodule Grizzly.Inclusions.InclusionRunner do
  @moduledoc false

  use GenServer

  alias Grizzly.SeqNumber
  alias Grizzly.Inclusions.InclusionRunner.Inclusion
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.ZWave.{Security, Command}

  @type opts :: {:controller_id, Grizzly.node_id()} | {:handler, pid()}

  def child_spec(args) do
    # Don't restart the inclusion if there is a failure
    %{id: __MODULE__, start: {__MODULE__, :start_link, [args]}, restart: :temporary}
  end

  def start_link(opts \\ []) do
    controller_id = Keyword.get(opts, :controller_id, 1)
    handler = Keyword.get(opts, :handler, self())

    GenServer.start_link(__MODULE__,
      controller_id: controller_id,
      handler: handler
    )
  end

  @spec seq_number(pid()) :: Grizzly.seq_number()
  def seq_number(runner) do
    GenServer.call(runner, :seq_number)
  end

  @spec add_node(pid()) :: :ok
  def add_node(runner) do
    GenServer.call(runner, :add_node)
  end

  @spec add_node_stop(pid()) :: :ok
  def add_node_stop(runner) do
    GenServer.call(runner, :add_node_stop)
  end

  @spec remove_node(pid()) :: :ok
  def remove_node(runner) do
    GenServer.call(runner, :remove_node)
  end

  @spec remove_node_stop(pid()) :: :ok
  def remove_node_stop(runner) do
    GenServer.call(runner, :remove_node_stop)
  end

  @spec grant_keys(pid, [Security.key()]) :: :ok
  def grant_keys(runner, security_keys) do
    GenServer.call(runner, {:grant_keys, security_keys})
  end

  @spec set_dsk(pid(), non_neg_integer()) :: :ok
  def set_dsk(runner, dsk \\ 0) do
    GenServer.call(runner, {:set_dsk, dsk})
  end

  def stop(runner) do
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
    send(inclusion.handler, {:grizzly, :inclusion, command})

    if inclusion.state == :complete do
      {:stop, :normal, inclusion}
    else
      {:noreply, inclusion}
    end
  end
end
