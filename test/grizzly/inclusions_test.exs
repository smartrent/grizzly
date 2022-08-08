defmodule Grizzly.InclusionsTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Inclusions, Report}
  alias Grizzly.ZWave.Command

  defmodule TestHandler do
    @moduledoc false

    @behaviour Grizzly.InclusionHandler

    alias Grizzly.{Inclusions, Report}
    alias Grizzly.ZWave.Command

    @impl Grizzly.InclusionHandler
    def handle_report(%Report{command: %Command{name: :node_add_keys_report}}, _opts) do
      Inclusions.grant_keys([:s2_unauthenticated])
    end

    def handle_report(%Report{command: %Command{name: :node_add_dsk_report}}, _opts) do
      Inclusions.set_input_dsk()
    end

    def handle_report(%Report{command: %Command{name: command_name} = command}, opts)
        when command_name in [:node_add_status, :node_remove_status] do
      test_pid = opts[:test_pid]

      send(test_pid, command)
    end

    def handle_report(_report, _opts) do
      :ok
    end

    @impl Grizzly.InclusionHandler
    def handle_timeout(_, _) do
      :ok
    end
  end

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

  test "S2 inclusions with handler" do
    :ok = Inclusions.add_node(s2: true, handler: {TestHandler, test_pid: self()})

    assert_receive %Grizzly.ZWave.Command{name: :node_add_status}, 1_500
  end

  test "crashing inclusion should return server back into idle state" do
    :ok = Inclusions.add_node()

    inclusions_pid = Process.whereis(Grizzly.InclusionServer)

    assert :node_adding = Inclusions.status()

    Process.exit(inclusions_pid, :kill)
    Process.sleep(500)

    assert :idle == Inclusions.status()
  end

  test "crashing exclusion should return server back into idle state" do
    :ok = Inclusions.remove_node()

    inclusions_pid = Process.whereis(Grizzly.InclusionServer)

    assert :node_removing = Inclusions.status()

    Process.exit(inclusions_pid, :kill)
    Process.sleep(500)

    assert :idle == Inclusions.status()
  end
end
