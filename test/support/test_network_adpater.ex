defmodule GrizzlyTest.InclusionAdapter do
  @moduledoc """
  An implementation of the inclusion adapter that is used for testing
  """

  @behaviour Grizzly.Inclusions.NetworkAdapter

  alias Grizzly.Report
  alias Grizzly.ZWave.DSK

  alias Grizzly.ZWave.Commands.{
    NodeAddStatus,
    NodeRemoveStatus,
    LearnModeSetStatus,
    NodeAddKeysReport,
    NodeAddDSKReport
  }

  @impl Grizzly.Inclusions.NetworkAdapter
  def init() do
    {:ok, %{timer_ref: nil}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def connect(_controller_id), do: :ok

  @impl Grizzly.Inclusions.NetworkAdapter
  def add_node(state, opts) do
    if opts[:s2] do
      {:ok, command} = NodeAddKeysReport.new(seq_number: 1, requested_keys: [:s2_unauthenticated])

      ref = Process.send_after(self(), build_report_msg(command), 00)

      {:ok, %{state | timer_ref: ref}}
    else
      {:ok, command} =
        NodeAddStatus.new(
          seq_number: 2,
          status: :done,
          node_id: 10000,
          listening?: false,
          basic_device_class: 4,
          generic_device_class: 8,
          specific_device_class: 6,
          command_classes: []
        )

      ref = Process.send_after(self(), build_report_msg(command), 500)

      {:ok, %{state | timer_ref: ref}}
    end
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def add_node_stop(state) do
    # cancel the add node timer
    new_state = cancel_timer(state)

    {:ok, command} =
      NodeAddStatus.new(
        seq_number: 2,
        status: :failed,
        node_id: 0,
        listening?: false,
        basic_device_class: 0,
        generic_device_class: 0,
        specific_device_class: 0,
        command_classes: []
      )

    Process.send_after(self(), build_report_msg(command), 100)

    {:ok, new_state}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def remove_node(state, _opts) do
    {:ok, command} = NodeRemoveStatus.new(seq_number: 2, status: :done, node_id: 100_000)

    ref = Process.send_after(self(), build_report_msg(command), 500)

    {:ok, %{state | timer_ref: ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def remove_node_stop(state) do
    new_state = cancel_timer(state)
    {:ok, command} = NodeRemoveStatus.new(seq_number: 2, status: :failed, node_id: 100_000)

    Process.send_after(self(), build_report_msg(command), 100)

    {:ok, new_state}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def learn_mode(state, _opts) do
    {:ok, command} = LearnModeSetStatus.new(seq_number: 1, status: :done)

    ref = Process.send_after(self(), build_report_msg(command), 500)

    {:ok, %{state | timer_ref: ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def learn_mode_stop(state) do
    new_state = cancel_timer(state)

    {:ok, command} = LearnModeSetStatus.new(seq_number: 1, status: :failed)

    Process.send_after(self(), build_report_msg(command), 100)

    {:ok, new_state}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def grant_s2_keys(_s2_keys, state) do
    new_state = cancel_timer(state)

    {:ok, command} =
      NodeAddDSKReport.new(seq_number: 1, input_dsk_length: 5, dsk: DSK.parse_pin("12345"))

    timer_ref = Process.send_after(self(), build_report_msg(command), 200)

    {:ok, %{new_state | timer_ref: timer_ref}}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def set_input_dsk(_dsk, _dsk_requested_length, state) do
    new_state = cancel_timer(state)

    {:ok, command} =
      NodeAddStatus.new(
        seq_number: 2,
        status: :done,
        node_id: 0,
        listening?: false,
        basic_device_class: 0,
        generic_device_class: 0,
        specific_device_class: 0,
        command_classes: []
      )

    Process.send_after(self(), build_report_msg(command), 300)

    {:ok, new_state}
  end

  defp build_report_msg(command) do
    {:grizzly, :report, Report.new(:complete, :command, 1, command: command)}
  end

  defp cancel_timer(state) do
    Process.cancel_timer(state.timer_ref)

    %{state | timer_ref: nil}
  end

  @impl Grizzly.Inclusions.NetworkAdapter
  def handle_timeout(status, _command_ref, state) do
    {status, state}
  end
end
