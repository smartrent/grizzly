defmodule Grizzly.InclusionsTest do
  use ExUnit.Case, async: false

  alias Grizzly.Inclusions
  alias Grizzly.Report
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DSK
  alias GrizzlyTest.Server.Handler

  @moduletag :inclusion

  defmodule TestHandler do
    @moduledoc false

    @behaviour Grizzly.InclusionHandler

    alias Grizzly.Inclusions
    alias Grizzly.Report
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
    :ok = Inclusions.remove_node(controller_id: 2000)

    Process.sleep(10)
    assert :node_removing = Inclusions.status()

    Handler.remove_node_status(2000, :done)
    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_remove_status
    assert Command.param!(command, :status) == :done

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "remove a node then stop it" do
    :ok = Inclusions.remove_node(controller_id: 301)

    Process.sleep(10)
    assert :node_removing = Inclusions.status()

    :ok = Inclusions.remove_node_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_remove_status
    assert Command.param!(command, :status) == :failed

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "add device" do
    :ok = Inclusions.add_node(controller_id: 2001)

    Process.sleep(10)
    assert :node_adding == Inclusions.status()

    Handler.add_node_status(2001, :done)
    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "start add device process then stop it" do
    :ok = Inclusions.add_node(controller_id: 301)

    Process.sleep(10)
    assert :node_adding = Inclusions.status()

    :ok = Inclusions.add_node_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :failed

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "start learn mode" do
    :ok = Inclusions.learn_mode(controller_id: 350)

    Process.sleep(10)
    assert :learn_mode = Inclusions.status()

    Handler.learn_mode_success(350)
    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :learn_mode_set_status
    assert Command.param!(command, :status) == :done

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "start learn mode and stop it" do
    :ok = Inclusions.learn_mode(controller_id: 351)

    Process.sleep(10)
    assert :learn_mode = Inclusions.status()

    :ok = Inclusions.learn_mode_stop()

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    assert command.name == :learn_mode_set_status
    assert Command.param!(command, :status) == :failed

    Process.sleep(10)
    assert Inclusions.status() == :idle
  end

  test "S2 unauthenticated" do
    :ok = Inclusions.add_node(s2: true, controller_id: 302)

    Process.sleep(10)
    assert :node_adding = Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: node_add_keys_report}},
                   1_000

    assert node_add_keys_report.name == :node_add_keys_report
    Process.sleep(10)
    assert :waiting_s2_keys = Inclusions.status()

    :ok = Inclusions.grant_keys([:s2_unauthenticated])

    assert_receive {:grizzly, :report, %Report{type: :command, command: dsk_report}}, 1_000

    assert dsk_report.name == :node_add_dsk_report
    assert %DSK{} = Command.param!(dsk_report, :dsk)
    Process.sleep(10)
    assert :waiting_dsk == Inclusions.status()

    {:ok, pin} = DSK.parse_pin("12345")
    :ok = Inclusions.set_input_dsk(pin)

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    Process.sleep(10)
    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done

    node_id = Command.param!(command, :node_id)

    expected_dsk = DSK.parse!("50285-18819-09924-30691-15973-33711-04005-03623")

    assert expected_dsk == Grizzly.Storage.get_node_dsk(node_id)

    assert %{
             status: :done,
             granted_keys: [:s2_unauthenticated],
             kex_fail_type: :none,
             smartstart?: false
           } = Grizzly.Storage.get_node_inclusion_info(node_id)
  end

  test "S2 authenticated" do
    :ok = Inclusions.add_node(s2: true, controller_id: 302)

    Process.sleep(10)
    assert :node_adding = Inclusions.status()

    assert_receive {:grizzly, :report, %Report{type: :command, command: node_add_keys_report}},
                   1_000

    assert node_add_keys_report.name == :node_add_keys_report
    Process.sleep(10)
    assert :waiting_s2_keys = Inclusions.status()

    :ok = Inclusions.grant_keys([:s2_authenticated])

    assert_receive {:grizzly, :report, %Report{type: :command, command: dsk_report}}, 1_000

    assert dsk_report.name == :node_add_dsk_report
    assert %DSK{} = Command.param!(dsk_report, :dsk)
    Process.sleep(10)
    assert :waiting_dsk == Inclusions.status()

    {:ok, pin} = DSK.parse_pin("12345")
    :ok = Inclusions.set_input_dsk(pin)

    assert_receive {:grizzly, :report, %Report{type: :command, command: command}}, 1_000

    Process.sleep(10)
    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done

    node_id = Command.param!(command, :node_id)

    expected_dsk = DSK.parse!("12345-18819-09924-30691-15973-33711-04005-03623")

    assert expected_dsk == Grizzly.Storage.get_node_dsk(node_id)

    assert %{
             status: :done,
             granted_keys: [:s2_authenticated],
             kex_fail_type: :none,
             smartstart?: false
           } = Grizzly.Storage.get_node_inclusion_info(node_id)
  end

  test "S2 inclusions with handler" do
    :ok = Inclusions.add_node(s2: true, handler: {TestHandler, test_pid: self()})

    assert_receive %Grizzly.ZWave.Command{name: :node_add_status}, 1_500
  end

  test "smartstart join" do
    dsk = DSK.parse!("29831-31413-38451-51291-12021-51481-12092-01212")
    Grizzly.InclusionServer.smart_start_join_started(dsk)

    {:ok, node_add_status} =
      Commands.create(
        :node_add_status,
        status: :done,
        node_id: 101,
        seq_number: 1,
        listening?: true,
        basic_device_class: :end_node,
        generic_device_class: :door_lock,
        specific_device_class: :secure_keypad_door_lock,
        command_classes: [
          non_secure_supported: [:basic, :zwaveplus_info],
          non_secure_controlled: [],
          secure_supported: [:alarm, :door_lock, :user_code],
          secure_controlled: []
        ],
        granted_keys: [:s2_access_control],
        kex_fail_type: :none,
        input_dsk: dsk
      )

    Grizzly.InclusionServer.continue_inclusion(302, node_add_status)

    Process.sleep(10)

    assert dsk == Grizzly.Storage.get_node_dsk(101)

    assert %{
             status: :done,
             smartstart?: true,
             granted_keys: [:s2_access_control],
             kex_fail_type: :none
           } == Grizzly.Storage.get_node_inclusion_info(101)

    assert %{
             listening?: true,
             basic_device_class: :end_node,
             generic_device_class: :door_lock,
             specific_device_class: :secure_keypad_door_lock,
             command_classes: [
               non_secure_supported: [:basic, :zwaveplus_info],
               non_secure_controlled: [],
               secure_supported: [:alarm, :door_lock, :user_code],
               secure_controlled: []
             ]
           } == Grizzly.Storage.get_node_info(101)
  end

  test "crashing inclusion should return server back into idle state" do
    :ok = Inclusions.add_node(controller_id: 302)

    inclusions_pid = Process.whereis(Grizzly.InclusionServer)

    Process.sleep(10)
    assert :node_adding = Inclusions.status()

    Process.exit(inclusions_pid, :kill)
    Process.sleep(500)

    assert :idle == Inclusions.status()
  end

  test "crashing exclusion should return server back into idle state" do
    :ok = Inclusions.remove_node(controller_id: 301)

    inclusions_pid = Process.whereis(Grizzly.InclusionServer)

    Process.sleep(10)
    assert :node_removing = Inclusions.status()

    Process.exit(inclusions_pid, :kill)
    Process.sleep(500)

    assert :idle == Inclusions.status()
  end
end
