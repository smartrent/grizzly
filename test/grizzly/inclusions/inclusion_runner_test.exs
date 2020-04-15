defmodule Grizzly.Inclusions.InclusionRunnerTest do
  use ExUnit.Case

  alias Grizzly.Inclusions.InclusionRunner
  alias Grizzly.ZWave.Command

  test "add a node to the network" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 300)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :inclusion, received_command}, 500

    assert received_command.name == :node_add_status
    assert Command.param!(received_command, :status) == :done
  end

  test "start inclusion but then stop it" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 301)
    # start inclusion
    :ok = InclusionRunner.add_node(runner)

    # simulate person waiting and deciding to stop inclusion
    :timer.sleep(500)

    :ok = InclusionRunner.add_node_stop(runner)

    assert_receive {:grizzly, :inclusion, received_command}, 500

    assert received_command.name == :node_add_status
    assert Command.param!(received_command, :status) == :failed
  end

  test "removes a node from the Z-Wave network" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 300)
    :ok = InclusionRunner.remove_node(runner)

    :timer.sleep(500)

    assert_receive {:grizzly, :inclusion, received_command}, 500

    assert received_command.name == :node_remove_status
    assert Command.param!(received_command, :status) == :done
  end

  test "start exclusion but then stop it" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 301)
    # start inclusion
    :ok = InclusionRunner.remove_node(runner)

    # simulate person waiting and deciding to stop inclusion
    :timer.sleep(500)

    :ok = InclusionRunner.remove_node_stop(runner)

    assert_receive {:grizzly, :inclusion, received_command}, 500

    assert received_command.name == :node_remove_status
    assert Command.param!(received_command, :status) == :failed
  end

  test "start s2 inclusion with out keys, adding s2 unauthenticated keys" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 302)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :inclusion, received_command}, 500

    assert received_command.name == :node_add_keys_report

    :ok = InclusionRunner.grant_keys(runner, [:s2_unauthenticated])

    assert_receive {:grizzly, :inclusion, command}, 1000

    assert command.name == :node_add_dsk_report
    assert Command.param!(command, :input_dsk_length) == 0

    :ok = InclusionRunner.set_dsk(runner)

    assert_receive {:grizzly, :inclusion, command}, 1000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done
    assert Command.param!(command, :keys_granted) == [:s2_unauthenticated]
  end

  test "start s2 inclusion with s2 authenticated" do
    {:ok, runner} = InclusionRunner.start_link(controller_id: 302)
    :ok = InclusionRunner.add_node(runner)

    assert_receive {:grizzly, :inclusion, command}, 500

    assert command.name == :node_add_keys_report

    :ok = InclusionRunner.grant_keys(runner, [:s2_authenticated])

    assert_receive {:grizzly, :inclusion, command}, 1000

    assert command.name == :node_add_dsk_report
    assert Command.param!(command, :input_dsk_length) == 2

    :ok = InclusionRunner.set_dsk(runner, 12345)

    assert_receive {:grizzly, :inclusion, command}, 1000

    assert command.name == :node_add_status
    assert Command.param!(command, :status) == :done
    assert Command.param!(command, :keys_granted) == [:s2_authenticated]
  end
end
