defmodule Grizzly.UnsolicitedServer.ResponseHandlerTest do
  use ExUnit.Case, async: true

  alias Grizzly.Associations
  alias Grizzly.Options
  alias Grizzly.UnsolicitedServer.ResponseHandler
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ZIPPacket

  setup ctx do
    assoc_server = :"#{ctx.test} #{System.unique_integer([:positive])} response_handler_assocs"
    multi_ch_server = :"#{ctx.test} #{System.unique_integer([:positive])} multi_channel_assocs"

    file1 =
      Path.join(
        System.tmp_dir(),
        "grizzly-#{System.unique_integer()}-response_handler_assocs.bin"
      )

    options = %Options{associations_file: file1}
    child_spec = Associations.child_spec([options, [name: assoc_server]])
    start_supervised!(%{child_spec | id: assoc_server})

    file2 =
      Path.join(
        System.tmp_dir(),
        "grizzly-#{System.unique_integer()}-response_handler_assocs_multi_channel.bin"
      )

    options = %Options{associations_file: file2}
    child_spec = Associations.child_spec([options, [name: multi_ch_server]])
    start_supervised!(%{child_spec | id: multi_ch_server})

    on_exit(fn ->
      File.rm(file1)
      File.rm(file2)
    end)

    {:ok,
     %{
       assoc_server: assoc_server,
       multi_channel_server: multi_ch_server
     }}
  end

  test "handle non-extra command" do
    {:ok, report} = Commands.create(:switch_binary_report, target_value: :off)
    response = make_response(report)

    assert [:ack, {:notify, report}] == ResponseHandler.handle_response(5, response)
  end

  test "handle association specific group get" do
    {:ok, asgg} = Commands.create(:association_specific_group_get)

    response = make_response(asgg)

    assert [:ack, {:send, asgr}] = ResponseHandler.handle_response(5, response)

    assert asgr.name == :association_specific_group_report
    assert Command.param!(asgr, :group) == 0
  end

  test "handle association get for known support grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = Commands.create(:association_get, grouping_identifier: 1)

    response = make_response(assoc_get)

    assert [:ack, {:send, assoc_report}] =
             ResponseHandler.handle_response(5, response, associations_server: server)

    assert assoc_report.name == :association_report
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handles association get for an unknown grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = Commands.create(:association_get, grouping_identifier: 100)

    response = make_response(assoc_get)

    assert [:ack, {:send, assoc_report}] =
             ResponseHandler.handle_response(5, response, associations_server: server)

    assert assoc_report.name == :association_report
    # should return the lifeline grouping if the requested identifier is unknown
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handle association set", %{assoc_server: server} do
    {:ok, assoc_set} = Commands.create(:association_set, grouping_identifier: 1, nodes: [1, 2, 3])

    response = make_response(assoc_set)

    assert [:ack] == ResponseHandler.handle_response(5, response, associations_server: server)
  end

  test "handle association groupings get" do
    {:ok, agg} = Commands.create(:association_groupings_get)
    assert [:ack, {:send, agr}] = ResponseHandler.handle_response(5, make_response(agg))

    assert agr.name == :association_groupings_report
  end

  describe "association group" do
    test "name get - known group (lifeline)" do
      {:ok, agng} = Commands.create(:association_group_name_get, group_id: 1)
      assert [:ack, {:send, agnr}] = ResponseHandler.handle_response(5, make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end

    test "name get - unknown group" do
      {:ok, agng} = Commands.create(:association_group_name_get, group_id: 123)

      assert [:ack, {:send, agnr}] = ResponseHandler.handle_response(5, make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end

    test "info get" do
      {:ok, agig} =
        Commands.create(:association_group_info_get,
          refresh_cache: false,
          group_id: 1,
          refresh_cache: false
        )

      assert [:ack, {:send, agir}] = ResponseHandler.handle_response(5, make_response(agig))

      assert agir.name == :association_group_info_report
      assert Command.param!(agir, :groups_info) == [[group_id: 1, profile: :general_lifeline]]
    end

    test "command list get" do
      {:ok, agclg} =
        Commands.create(:association_group_command_list_get, cache_allowed: false, group_id: 1)

      assert [:ack, {:send, agclr}] = ResponseHandler.handle_response(5, make_response(agclg))

      assert agclr.name == :association_group_command_list_report
      assert Command.param!(agclr, :commands) == [:device_reset_locally_notification]
    end
  end

  describe "supervision" do
    test "get" do
      {:ok, sup_get} =
        Commands.create(
          :supervision_get,
          status_updates: :one_now,
          session_id: 11,
          encapsulated_command: <<113, 5, 0, 0, 0, 255, 6, 254, 0>>
        )

      assert [:ack, {:notify, notify_command}, {:send, report}] =
               ResponseHandler.handle_response(5, make_response(sup_get))

      assert notify_command.name == :alarm_report

      assert report.name == :supervision_report
      assert Command.param!(report, :session_id) == 11
      assert Command.param!(report, :more_status_updates) == :last_report
      assert Command.param!(report, :status) == :success
    end
  end

  describe "multi channel association" do
    test "groupings get" do
      {:ok, mcagg} = Commands.create(:multi_channel_association_groupings_get)

      assert [:ack, {:send, mcagr}] = ResponseHandler.handle_response(5, make_response(mcagg))

      assert mcagr.name == :multi_channel_association_groupings_report

      assert Command.param!(mcagr, :supported_groupings) == 1
    end

    test "get", %{multi_channel_server: server} do
      {:ok, mcag} = Commands.create(:multi_channel_association_get, grouping_identifier: 1)

      assert [:ack, {:send, mcar}] =
               ResponseHandler.handle_response(5, make_response(mcag),
                 associations_server: server
               )

      assert mcar.name == :multi_channel_association_report
      assert is_list(Command.param!(mcar, :nodes))
    end

    test "set", %{multi_channel_server: server} do
      {:ok, mcas} =
        Commands.create(
          :multi_channel_association_set,
          grouping_identifier: 1,
          nodes: [1, 2, 3, 4],
          node_endpoints: [%{node: 5, endpoint: 6, bit_address: 0}]
        )

      assert [:ack] =
               ResponseHandler.handle_response(5, make_response(mcas),
                 associations_server: server
               )
    end

    test "remove", %{multi_channel_server: server} do
      {:ok, mcar} =
        Commands.create(:multi_channel_association_remove,
          grouping_identifier: 1,
          nodes: [],
          node_endpoints: []
        )

      assert [:ack] =
               ResponseHandler.handle_response(5, make_response(mcar),
                 associations_server: server
               )
    end
  end

  test "version get query" do
    {:ok, version_get} = Commands.create(:version_command_class_get, command_class: :association)

    assert [:ack, {:send, version_report}] =
             ResponseHandler.handle_response(5, make_response(version_get))

    assert version_report.name == :version_command_class_report
    assert Command.param!(version_report, :version) == 3
  end

  defp make_response(command) do
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, 1)
    zip_packet
  end
end
