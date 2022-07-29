defmodule Grizzly.InclusionsTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Inclusions, Report}
  alias Grizzly.ZWave.Command

  test "remove a node" do
    :ok = Inclusions.remove_node()

    assert :node_removing = Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_remove_status
    assert Command.param!(command, :status) == :done

    assert Inclusions.status() == :idle
  end

  test "remove a node then stop it" do
    :ok = Inclusions.remove_node()

    assert :node_removing = Inclusions.status()

    :ok = Inclusions.remove_node_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_remove_status
    assert Command.param!(command, :status) == :failed

    assert Inclusions.status() == :idle
  end

  test "add device" do
    :ok = Inclusions.add_node()

    assert :node_adding == Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done

    assert Inclusions.status() == :idle
  end

  test "start add device process then stop it" do
    :ok = Inclusions.add_node()

    assert :node_adding = Inclusions.status()

    :ok = Inclusions.add_node_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :failed

    assert Inclusions.status() == :idle
  end

  test "start learn mode" do
    :ok = Inclusions.learn_mode()

    assert :learn_mode = Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :learn_mode_set_status
    assert Command.param!(command, :status) == :done

    assert Inclusions.status() == :idle
  end

  test "start learn mode and stop it" do
    :ok = Inclusions.learn_mode()

    assert :learn_mode = Inclusions.status()

    :ok = Inclusions.learn_mode_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :learn_mode_set_status
    assert Command.param!(command, :status) == :failed

    assert Inclusions.status() == :idle
  end

  test "S2 inclusion" do
    :ok = Inclusions.add_node(s2: true)

    assert :node_adding = Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: node_add_keys_report}},
                   1_000

    assert node_add_keys_report.name == :node_add_keys_report
    assert :waiting_s2_keys = Inclusions.status()

    :ok = Inclusions.grant_keys([:s2_unauthenticated])

    assert_receive {:grizzly, :report, %Report{type: :command, command: dsk_report}}, 1_000

    assert dsk_report.name == :node_add_dsk_report
    assert :waiting_dsk == Inclusions.status()

    :ok = Inclusions.set_input_dsk()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done
  end
end
