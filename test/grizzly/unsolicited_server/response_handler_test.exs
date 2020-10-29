defmodule Grizzly.UnsolicitedServer.ResponseHandlerTest do
  use ExUnit.Case, async: true

  alias Grizzly.{Associations, Options, ZWave}
  alias Grizzly.UnsolicitedServer.ResponseHandler
  alias Grizzly.Transport.Response
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationGet,
    AssociationGroupingsGet,
    AssociationGroupNameGet,
    AssociationSet,
    AssociationSpecificGroupGet,
    SupervisionGet,
    SwitchBinaryReport,
    ZIPPacket
  }

  setup do
    options = %Options{associations_file: "/tmp/response_handler_assocs"}
    {:ok, _} = Associations.start_link(options, name: :response_handler_assocs)

    on_exit(fn ->
      File.rm("/tmp/response_handler_assocs")
    end)

    {:ok, %{assoc_server: :response_handler_assocs}}
  end

  test "handle supervision get" do
    {:ok, report} = SwitchBinaryReport.new(target_value: :on)

    {:ok, supervision_get} =
      SupervisionGet.new(
        encapsulated_command: ZWave.to_binary(report),
        session_id: 1,
        status_updates: :one_now
      )

    response = make_response(supervision_get)

    assert {:notify, report} == ResponseHandler.handle_response(response)
  end

  test "handle non-extra command" do
    {:ok, report} = SwitchBinaryReport.new(target_value: :off)
    response = make_response(report)

    assert {:notify, report} == ResponseHandler.handle_response(response)
  end

  test "handle association specific group get" do
    {:ok, asgg} = AssociationSpecificGroupGet.new()

    response = make_response(asgg)

    assert {:send, asgr} = ResponseHandler.handle_response(response)

    assert asgr.name == :association_specific_group_report
    assert Command.param!(asgr, :group) == 0
  end

  test "handle association get for known support grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = AssociationGet.new(grouping_identifier: 1)

    response = make_response(assoc_get)

    assert {:send, assoc_report} =
             ResponseHandler.handle_response(response, associations_server: server)

    assert assoc_report.name == :association_report
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handles association get for an unknown grouping identifier", %{assoc_server: server} do
    {:ok, assoc_get} = AssociationGet.new(grouping_identifier: 100)

    response = make_response(assoc_get)

    assert {:send, assoc_report} =
             ResponseHandler.handle_response(response, associations_server: server)

    assert assoc_report.name == :association_report
    # should return the lifeline grouping if the requested identifier is unknown
    assert Command.param!(assoc_report, :grouping_identifier) == 1
  end

  test "handle association set", %{assoc_server: server} do
    {:ok, assoc_set} = AssociationSet.new(grouping_identifier: 1, nodes: [1, 2, 3])

    response = make_response(assoc_set)

    assert :ok == ResponseHandler.handle_response(response, associations_server: server)
  end

  test "handle association groupings get" do
    {:ok, agg} = AssociationGroupingsGet.new()
    assert {:send, agr} = ResponseHandler.handle_response(make_response(agg))

    assert agr.name == :association_groupings_report
  end

  describe "association group" do
    test "name get - known group (lifeline)" do
      {:ok, agng} = AssociationGroupNameGet.new(group_id: 1)
      assert {:send, agnr} = ResponseHandler.handle_response(make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end

    test "name get - unknown group" do
      {:ok, agng} = AssociationGroupNameGet.new(group_id: 123)

      assert {:send, agnr} = ResponseHandler.handle_response(make_response(agng))

      assert agnr.name == :association_group_name_report
      assert Command.param!(agnr, :group_id) == 1
      assert Command.param!(agnr, :name) == "Lifeline"
    end
  end

  defp make_response(command) do
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, 1)
    %Response{port: 1234, ip_address: {0, 0, 0, 0}, command: zip_packet}
  end
end
