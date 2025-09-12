defmodule Grizzly.UnsolicitedServer.ResponseHandlerTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Associations, Options}
  alias Grizzly.UnsolicitedServer.ResponseHandler
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationGet,
    AssociationGroupCommandListGet,
    AssociationGroupInfoGet,
    AssociationGroupingsGet,
    AssociationGroupNameGet,
    AssociationSet,
    AssociationSpecificGroupGet,
    MultiChannelAssociationGet,
    MultiChannelAssociationGroupingsGet,
    MultiChannelAssociationRemove,
    MultiChannelAssociationSet,
    SupervisionGet,
    SwitchBinaryReport,
    VersionCommandClassGet,
    ZIPPacket
  }

  setup_all do
    options = %Options{associations_file: "/tmp/response_handler_assocs"}
    {:ok, _} = Associations.start_link(options, name: :response_handler_assocs)

    multi_channel_options = %Options{
      associations_file: "/tmp/response_handler_assocs_multi_channel"
    }

    {:ok, _} = Associations.start_link(multi_channel_options, name: :multi_channel_assocs)

    on_exit(fn ->
      File.rm("/tmp/response_handler_assocs")
      File.rm("/tmp/response_handler_assocs_multi_channel")
    end)

    {:ok, %{assoc_server: :response_handler_assocs, multi_channel_server: :multi_channel_assocs}}
  end

  test "handle non-extra command" do
    {:ok, report} = SwitchBinaryReport.new(target_value: :off)
    response = make_response(report)

    assert [:ack, {:notify, report}] == ResponseHandler.handle_response(5, response)
  end

  test "handle association specific group get" do
    {:ok, asgg} = AssociationSpecificGroupGet.new()

    response = make_response(asgg)

    assert [:ack, {:send, asgr}] = ResponseHandler.handle_response(5, response)

    assert asgr.name == :association_specific_group_report
    assert Command.param!(asgr, :group) == 0
  end

  test "handle association get for known support grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = AssociationGet.new(grouping_identifier: 1)

    response = make_response(assoc_get)

    assert [:ack, {:send, assoc_report}] =
             ResponseHandler.handle_response(5, response, associations_server: server)

    assert assoc_report.name == :association_report
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handles association get for an unknown grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = AssociationGet.new(grouping_identifier: 100)

    response = make_response(assoc_get)

    assert [:ack, {:send, assoc_report}] =
             ResponseHandler.handle_response(5, response, associations_server: server)

    assert assoc_report.name == :association_report
    # should return the lifeline grouping if the requested identifier is unknown
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handle association set", %{assoc_server: server} do
    {:ok, assoc_set} = AssociationSet.new(grouping_identifier: 1, nodes: [1, 2, 3])

    response = make_response(assoc_set)

    assert [:ack] == ResponseHandler.handle_response(5, response, associations_server: server)
  end

  test "handle association groupings get" do
    {:ok, agg} = AssociationGroupingsGet.new()
    assert [:ack, {:send, agr}] = ResponseHandler.handle_response(5, make_response(agg))

    assert agr.name == :association_groupings_report
  end

  describe "association group" do
    test "name get - known group (lifeline)" do
      {:ok, agng} = AssociationGroupNameGet.new(group_id: 1)
      assert [:ack, {:send, agnr}] = ResponseHandler.handle_response(5, make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end

    test "name get - unknown group" do
      {:ok, agng} = AssociationGroupNameGet.new(group_id: 123)

      assert [:ack, {:send, agnr}] = ResponseHandler.handle_response(5, make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end

    test "info get" do
      {:ok, agig} =
        AssociationGroupInfoGet.new(refresh_cache: false, group_id: 1, refresh_cache: false)

      assert [:ack, {:send, agir}] = ResponseHandler.handle_response(5, make_response(agig))

      assert agir.name == :association_group_info_report
      assert Command.param!(agir, :groups_info) == [[group_id: 1, profile: :general_lifeline]]
    end

    test "command list get" do
      {:ok, agclg} = AssociationGroupCommandListGet.new(cache_allowed: false, group_id: 1)

      assert [:ack, {:send, agclr}] = ResponseHandler.handle_response(5, make_response(agclg))

      assert agclr.name == :association_group_command_list_report
      assert Command.param!(agclr, :commands) == [:device_reset_locally_notification]
    end
  end

  describe "supervision" do
    test "get" do
      {:ok, sup_get} =
        SupervisionGet.new(
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
      {:ok, mcagg} = MultiChannelAssociationGroupingsGet.new()

      assert [:ack, {:send, mcagr}] = ResponseHandler.handle_response(5, make_response(mcagg))

      assert mcagr.name == :multi_channel_association_groupings_report

      assert Command.param!(mcagr, :supported_groupings) == 1
    end

    test "get", %{multi_channel_server: server} do
      {:ok, mcag} = MultiChannelAssociationGet.new(grouping_identifier: 1)

      assert [:ack, {:send, mcar}] =
               ResponseHandler.handle_response(5, make_response(mcag),
                 associations_server: server
               )

      assert mcar.name == :multi_channel_association_report
      assert is_list(Command.param!(mcar, :nodes))
    end

    test "set", %{multi_channel_server: server} do
      {:ok, mcas} =
        MultiChannelAssociationSet.new(
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
        MultiChannelAssociationRemove.new(grouping_identifier: 1, nodes: [], node_endpoints: [])

      assert [:ack] =
               ResponseHandler.handle_response(5, make_response(mcar),
                 associations_server: server
               )
    end
  end

  test "version get query" do
    {:ok, version_get} = VersionCommandClassGet.new(command_class: :association)

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
