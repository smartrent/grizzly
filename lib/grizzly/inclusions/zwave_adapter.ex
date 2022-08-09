defmodule Grizzly.Inclusions.ZWaveAdapter do
  @moduledoc """
  An implementation of the inclusion network adapter that talks to the Z-Wave
  network
  """

  @behaviour Grizzly.Inclusions.NetworkAdapter

  @inclusion_timeout 120_000

  require Logger

  alias Grizzly.Connection
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.SeqNumber

  alias Grizzly.ZWave.Commands.{
    NodeAdd,
    NodeRemove,
    NodeAddKeysSet,
    NodeAddDSKSet,
    LearnModeSet
  }

  @impl Grizzly.Inclusions.NetworkAdapter
  def init() do
    {:ok, %{command_ref: nil}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def connect(controller_id) do
    {:ok, _pid} = Connection.open(controller_id, mode: :async)

    :ok
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def add_node(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    controller_id = opts[:controller_id] || 1
    timeout = opts[:timeout] || @inclusion_timeout

    with {:ok, command} <- NodeAdd.new(seq_number: seq_number),
         {:ok, command_ref} <-
           AsyncConnection.send_command(controller_id, command, timeout: timeout) do
      {:ok, %{state | command_ref: command_ref}}
    end
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def add_node_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} = NodeAdd.new(seq_number: seq_number, mode: :node_add_stop)

    {:ok, command_ref} = AsyncConnection.send_command(1, command)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def remove_node(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    timeout = opts[:timeout] || @inclusion_timeout

    {:ok, command} = NodeRemove.new(seq_number: seq_number)
    {:ok, command_ref} = AsyncConnection.send_command(1, command, timeout: timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def remove_node_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} = NodeRemove.new(seq_number: seq_number, mode: :remove_node_stop)

    {:ok, command_ref} = AsyncConnection.send_command(1, command)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def learn_mode(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    timeout = opts[:timeout] || @inclusion_timeout

    {:ok, command} =
      LearnModeSet.new(
        seq_number: seq_number,
        mode: :direct_range_only,
        return_interview_status: :off
      )

    {:ok, command_ref} = AsyncConnection.send_command(1, command, timeout: timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def learn_mode_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      LearnModeSet.new(seq_number: seq_number, mode: :disable, return_interview_status: :off)

    {:ok, command_ref} = AsyncConnection.send_command(1, command, timeout: @inclusion_timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def grant_s2_keys(s2_keys, state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      NodeAddKeysSet.new(seq_number: seq_number, granted_keys: s2_keys, csa: false, accept: true)

    {:ok, command_ref} = AsyncConnection.send_command(1, command, timeout: @inclusion_timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def set_input_dsk(dsk, requested_length, state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      NodeAddDSKSet.new(
        seq_number: seq_number,
        accept: true,
        input_dsk_length: requested_length,
        input_dsk: dsk
      )

    {:ok, command_ref} = AsyncConnection.send_command(1, command, timeout: @inclusion_timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def handle_timeout(state, _old_ref, adapter_state)
      when state in [:node_adding, :waiting_s2_keys, :waiting_dsk] do
    {:ok, new_state} = add_node_stop(adapter_state)

    {:node_add_stopping, new_state}
  end

  def handle_timeout(:node_removing, command_ref, %{command_ref: command_ref} = state) do
    {:ok, new_state} = remove_node_stop(state)

    {:node_remove_stopping, new_state}
  end

  def handle_timeout(inclusion_state, _command_ref, state)
      when inclusion_state in [:idle, :node_add_stopping] do
    {inclusion_state, state}
  end
end
