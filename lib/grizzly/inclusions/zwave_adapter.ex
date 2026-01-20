defmodule Grizzly.Inclusions.ZWaveAdapter do
  @moduledoc false

  # For certification to pass, this must be at least the sum of the S2 bootstrapping
  # timeouts TA1 (10), TA2 (10), TA3 (10), TA4 (10), TA5 (10), TAI1 (240), and TAI2 (240).
  alias Grizzly.Connection
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.Inclusions
  alias Grizzly.SeqNumber
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.Security

  require Logger

  @inclusion_timeout :timer.seconds(530)

  @type state :: %{
          command_ref: reference() | nil,
          controller_id: Grizzly.node_id()
        }

  @spec init() :: {:ok, state()}
  def init() do
    {:ok, %{command_ref: nil, controller_id: 1}}
  end

  defp connect(controller_id) do
    {:ok, _pid} = Connection.open(controller_id, mode: :async)

    :ok
  end

  @spec add_node(state(), [Inclusions.opt()]) :: {:ok, state()} | {:error, :unknown_command}
  def add_node(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    controller_id = opts[:controller_id] || 1
    timeout = opts[:timeout] || @inclusion_timeout

    params = opts |> Keyword.take([:mode, :tx_opt]) |> Keyword.put(:seq_number, seq_number)

    with {:ok, command} <- Commands.create(:node_add, params),
         :ok <- connect(controller_id),
         {:ok, command_ref} <-
           AsyncConnection.send_command(controller_id, command, timeout: timeout) do
      {:ok, %{state | command_ref: command_ref, controller_id: controller_id}}
    end
  end

  @spec add_node_stop(state()) :: {:ok, state()}
  def add_node_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} = Commands.create(:node_add, seq_number: seq_number, mode: :node_add_stop)

    connect(state.controller_id)
    {:ok, command_ref} = AsyncConnection.send_command(state.controller_id, command)

    {:ok, %{state | command_ref: command_ref, controller_id: 1}}
  end

  @spec remove_node(state(), [Inclusions.opt()]) :: {:ok, state()}
  def remove_node(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    controller_id = opts[:controller_id] || 1
    timeout = opts[:timeout] || @inclusion_timeout

    connect(controller_id)
    {:ok, command} = Commands.create(:node_remove, seq_number: seq_number)
    {:ok, command_ref} = AsyncConnection.send_command(controller_id, command, timeout: timeout)

    {:ok, %{state | command_ref: command_ref, controller_id: controller_id}}
  end

  @spec remove_node_stop(state()) :: {:ok, state()}
  def remove_node_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      Commands.create(:node_remove, seq_number: seq_number, mode: :remove_node_stop)

    connect(state.controller_id)
    {:ok, command_ref} = AsyncConnection.send_command(state.controller_id, command)

    {:ok, %{state | command_ref: command_ref, controller_id: 1}}
  end

  @spec learn_mode(state(), [Inclusions.opt()]) :: {:ok, state()}
  def learn_mode(state, opts) do
    seq_number = SeqNumber.get_and_inc()
    controller_id = opts[:controller_id] || 1
    timeout = opts[:timeout] || @inclusion_timeout

    params =
      opts
      |> Keyword.take([:mode, :return_interview_status])
      |> Keyword.put(:seq_number, seq_number)
      |> Keyword.put_new(:mode, :direct_range_only)
      |> Keyword.put_new(:return_interview_status, :off)

    {:ok, command} = Commands.create(:learn_mode_set, params)

    connect(controller_id)
    {:ok, command_ref} = AsyncConnection.send_command(controller_id, command, timeout: timeout)

    {:ok, %{state | command_ref: command_ref, controller_id: controller_id}}
  end

  @spec learn_mode_stop(state()) :: {:ok, state()}
  def learn_mode_stop(state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      Commands.create(:learn_mode_set,
        seq_number: seq_number,
        mode: :disable,
        return_interview_status: :off
      )

    {:ok, command_ref} = AsyncConnection.send_command(state.controller_id, command)

    {:ok, %{state | command_ref: command_ref, controller_id: 1}}
  end

  @spec grant_s2_keys([Security.key()], state()) :: {:ok, state()}
  def grant_s2_keys(s2_keys, state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      Commands.create(:node_add_keys_set,
        seq_number: seq_number,
        granted_keys: s2_keys,
        csa: false,
        accept: true
      )

    connect(state.controller_id)

    {:ok, command_ref} =
      AsyncConnection.send_command(state.controller_id, command, timeout: @inclusion_timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @spec set_input_dsk(DSK.t(), non_neg_integer(), state()) :: {:ok, state()}
  def set_input_dsk(dsk, requested_length, state) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, command} =
      Commands.create(:node_add_dsk_set,
        seq_number: seq_number,
        accept: true,
        input_dsk_length: requested_length,
        input_dsk: dsk
      )

    connect(state.controller_id)

    {:ok, command_ref} =
      AsyncConnection.send_command(state.controller_id, command, timeout: @inclusion_timeout)

    {:ok, %{state | command_ref: command_ref}}
  end

  @spec handle_timeout(Inclusions.status(), reference(), state()) ::
          {Inclusions.status(), state()}
  def handle_timeout(state, _old_ref, adapter_state)
      when state in [
             :node_adding,
             :waiting_s2_keys,
             :waiting_dsk,
             :dsk_input_set,
             :node_add_stopping
           ] do
    {:ok, new_state} = add_node_stop(adapter_state)

    {:node_add_stopping, new_state}
  end

  def handle_timeout(state, _command_ref, adapter_state)
      when state in [:node_removing, :node_remove_stopping] do
    {:ok, new_state} = remove_node_stop(adapter_state)

    {:node_remove_stopping, new_state}
  end

  def handle_timeout(state, _command_ref, adapter_state)
      when state in [:learn_mode, :learn_mode_stopping] do
    {:ok, new_state} = learn_mode_stop(adapter_state)

    {:learn_mode_stopping, new_state}
  end

  def handle_timeout(:idle, _command_ref, adapter_state) do
    {:idle, adapter_state}
  end
end
