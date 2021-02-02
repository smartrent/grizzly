defmodule Grizzly.Inclusions.InclusionRunner.InclusionTest do
  use ExUnit.Case, async: true

  alias Grizzly.Inclusions.InclusionRunner.Inclusion
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    NodeAddKeysReport,
    NodeAddStatus,
    NodeRemoveStatus,
    NodeAddDSKReport
  }

  describe "handling command" do
    test "node add keys report command" do
      inclusion = %Inclusion{state: :node_adding}

      {:ok, node_add_keys_report} =
        NodeAddKeysReport.new(seq_number: 0x01, csa: false, requested_keys: :s2_authenticated)

      assert %Inclusion{state: :keys_requested} ==
               Inclusion.handle_command(inclusion, node_add_keys_report)
    end

    test "node add status" do
      inclusion = %Inclusion{state: :node_adding}
      {:ok, node_add_status_report} = NodeAddStatus.new()

      assert %Inclusion{state: :complete} ==
               Inclusion.handle_command(inclusion, node_add_status_report)
    end

    test "node remove status" do
      inclusion = %Inclusion{state: :node_removing}

      {:ok, node_remove_status_report} =
        NodeRemoveStatus.new(seq_number: 0x01, status: :done, node_id: 101)

      assert %Inclusion{state: :complete} ==
               Inclusion.handle_command(inclusion, node_remove_status_report)
    end

    test "node add dsk report" do
      inclusion = %Inclusion{state: :keys_granted}

      {:ok, node_add_dsk_report} =
        NodeAddDSKReport.new(seq_number: 0x01, dsk: "0", input_dsk_length: 0)

      assert %Inclusion{state: :dsk_requested, dsk_input_length: 0} ==
               Inclusion.handle_command(inclusion, node_add_dsk_report, dsk_input_length: 0)
    end
  end

  describe "generating the next command" do
    test "start state to desired state of node adding" do
      inclusion = %Inclusion{}
      {zwave_command, new_inclusion} = Inclusion.next_command(inclusion, :node_adding, 0x01)

      assert %Command{name: :node_add} = zwave_command
      assert %Inclusion{state: :node_adding} == new_inclusion
    end

    test "move from node adding to node adding stop" do
      inclusion = %Inclusion{state: :node_adding}

      {zwave_command, new_inclusion} = Inclusion.next_command(inclusion, :node_adding_stop, 0x01)

      assert %Command{name: :node_add} = zwave_command
      assert Command.param!(zwave_command, :mode) == :node_add_stop
      assert %Inclusion{state: :node_adding_stop} == new_inclusion
    end

    test "move state to desired state of node removing" do
      inclusion = %Inclusion{}

      {zwave_command, new_inclusion} = Inclusion.next_command(inclusion, :node_removing, 0x01)

      assert %Command{name: :node_remove} = zwave_command
      assert %Inclusion{state: :node_removing} == new_inclusion
    end

    test "move state from node removing to node removing stop" do
      inclusion = %Inclusion{state: :node_removing}

      {zwave_command, new_inclusion} =
        Inclusion.next_command(inclusion, :node_removing_stop, 0x01)

      assert %Command{name: :node_remove} = zwave_command
      assert Command.param!(zwave_command, :mode) == :remove_node_stop
      assert %Inclusion{state: :node_removing_stop} == new_inclusion
    end

    test "move state from keys requested to keys granted" do
      inclusion = %Inclusion{state: :keys_requested}

      {zwave_command, new_inclusion} =
        Inclusion.next_command(inclusion, :keys_granted, 0x01, keys: [:s2_unauthenticated])

      assert %Command{name: :node_add_keys_set} = zwave_command
      assert %Inclusion{state: :keys_granted} == new_inclusion
    end

    test "when input dsk size is less than the requested" do
      inclusion = %Inclusion{state: :dsk_requested, dsk_input_length: 2}
      {zwave_command, new_inclusion} = Inclusion.next_command(inclusion, :dsk_set, 0x01, dsk: 159)
      assert %Command{name: :node_add_dsk_set} = zwave_command
      assert %Inclusion{dsk_input_length: 2, state: :dsk_set} == new_inclusion
    end
  end
end
