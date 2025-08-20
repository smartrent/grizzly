defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  # module helper for handling various different responses from the Z-Wave PAN
  # network

  require Logger

  alias Grizzly.{Associations, ZWave}
  alias Grizzly.VersionReports
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationGroupCommandListReport,
    AssociationGroupInfoReport,
    AssociationGroupingsReport,
    AssociationGroupNameReport,
    AssociationReport,
    AssociationSpecificGroupReport,
    MultiChannelAssociationGroupingsReport,
    MultiChannelAssociationReport,
    SupervisionReport,
    ZIPKeepAlive,
    ZIPPacket
  }

  @type opt() :: {:association_server, GenServer.name()}

  @type action() ::
          {:notify, Command.t()} | {:send, Command.t()} | {:forward_to_controller, Command.t()}

  defguardp is_supervision_status_action(a) when is_tuple(a) and elem(a, 0) == :supervision_status

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Grizzly.node_id(), Command.t(), [opt()]) ::
          [action()] | {:error, reason :: any()}
  def handle_response(node_id, command, opts \\ []) do
    cond do
      command.name == :keep_alive ->
        handle_keep_alive(command)

      # Everything else should be Z/IP encapsulated
      command.name != :zip_packet ->
        Logger.warning(
          "[Grizzly] Unsolicited server expected a Z/IP Packet, got: #{inspect(command)}"
        )

        []

      # Nothing to do for ACK responses
      ZIPPacket.ack_response?(command) ->
        []

      # Warn about nack responses
      ZIPPacket.nack_response?(command) ->
        Logger.warning(
          "[Grizzly] Unsolicited server received a nack response: #{inspect(command)}"
        )

        []

      # There's not much we can do about the nack+waiting condition when replying
      # from the unsolicited server.
      ZIPPacket.nack_waiting?(command) ->
        []

      # Pretty much anything else should be a Z/IP Packet carrying a command.
      true ->
        with internal_cmd when not is_nil(internal_cmd) <- Command.param!(command, :command),
             actions when is_list(actions) <- handle_command(node_id, internal_cmd, opts) do
          actions = Enum.reject(actions, &is_supervision_status_action/1)
          [:ack | actions]
        else
          {:error, _any} = error ->
            error

          nil ->
            Logger.warning(
              "[Grizzly] Unsolicited server received an unexpectedly empty Z/IP Packet: #{inspect(command)}"
            )

            []
        end
    end
  end

  defp handle_keep_alive(cmd) do
    case Command.param!(cmd, :ack_flag) do
      :ack_request ->
        {:ok, ack_response} = ZIPKeepAlive.new(ack_flag: :ack_response)
        [{:send_raw, ack_response}]

      _ ->
        []
    end
  end

  defp handle_command(node_id, %Command{name: :supervision_get} = command, opts) do
    encapsulated_command = Command.param!(command, :encapsulated_command)

    case ZWave.from_binary(encapsulated_command) do
      {:ok, report} ->
        # We need to process the internal command and get the actions that need
        # to be preformed. The supervision report must come last in the chain of
        # actions. See SDS13783 section 3.7.2.2 for more information.
        actions = handle_command(node_id, report, opts)

        {_, supervision_status} =
          Enum.find(actions, {:supervision_status, :success}, &is_supervision_status_action/1)

        actions = Enum.reject(actions, &is_supervision_status_action/1)

        {:ok, supervision_report} = make_supervision_report(command, supervision_status)
        actions ++ [{:send, supervision_report}]

      {:error, reason} ->
        Logger.warning(
          "Failed to parse: #{inspect(encapsulated_command)} notification for reason: #{inspect(reason)}"
        )

        {:ok, supervision_report} = make_supervision_report(command, :no_support)
        [{:send, supervision_report}]
    end
  end

  defp handle_command(_node_id, %Command{name: :basic_set}, _opts) do
    [{:supervision_status, :no_support}]
  end

  # When an inclusion controller adds a node, we'll receive network management
  # commands via the unsolicited server.
  defp handle_command(node_id, %Command{name: inclusion_cmd} = cmd, _opts)
       when inclusion_cmd in [
              :node_add_status,
              :node_add_keys_report,
              :node_add_dsk_report,
              :extended_node_add_status,
              :node_remove_status
            ] do
    Logger.debug(
      "[UnsolicitedServer] Received unsolicited inclusion command: #{inspect(cmd, pretty: true)}"
    )

    Grizzly.Inclusions.continue_inclusion(node_id, cmd)

    # do nothing. the configured inclusion handler will take care of it.
    []
  end

  defp handle_command(_node_id, %Command{name: :association_specific_group_get}, _) do
    case AssociationSpecificGroupReport.new(group: 0) do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(_node_id, %Command{name: :association_get}, opts) do
    # According the the Z-Wave specification if a get request contains an
    # unsupported grouping identifier then we should report back the grouping
    # information for group number 1. Since right now we only support that
    # group we don't need to check because we will always just send back the
    # grouping information for group id 1.
    associations_server = Keyword.get(opts, :associations_server, Associations)

    {:ok, respond_with_command} =
      case Associations.get(associations_server, 1) do
        nil ->
          AssociationReport.new(
            grouping_identifier: 1,
            max_nodes_supported: 1,
            nodes: []
          )

        association ->
          AssociationReport.new(
            grouping_identifier: association.grouping_id,
            max_nodes_supported: 1,
            nodes: association.node_ids
          )
      end

    [{:send, respond_with_command}]
  end

  defp handle_command(_node_id, %Command{name: :association_set} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)

      case Associations.save(associations_server, grouping_identifier, nodes) do
        :ok -> [supervision_status: :success]
        _ -> [supervision_status: :fail]
      end
    else
      [supervision_status: :fail]
    end
  end

  defp handle_command(_node_id, %Command{name: :association_groupings_get}, _opts) do
    case AssociationGroupingsReport.new(supported_groupings: 1) do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(_node_id, %Command{name: :association_remove} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_id = Command.param!(command, :grouping_identifier)
    nodes = Command.param!(command, :nodes)

    # This case matching is based off a table from the Z-Wave specification
    # Right now we only have one association grouping, so the first and third
    # match are the same right now. I want to keep the matching explicit right
    # now as I hope it will enable quicker understand to any future work that
    # will be as it maps nicely to the documentation found in the Z-Wave
    # specification.
    case {grouping_id, nodes} do
      {1, []} ->
        :ok = Associations.delete_all_nodes_from_grouping(associations_server, grouping_id)
        []

      {1, nodes} ->
        case Associations.delete_nodes_from_grouping(associations_server, grouping_id, nodes) do
          :ok -> []
          error -> error
        end

      {0, []} ->
        :ok = Associations.delete_all(associations_server)
        []

      {0, nodes} ->
        :ok = Associations.delete_nodes_from_all_groupings(associations_server, nodes)
        []

      _ ->
        []
    end
  end

  defp handle_command(_node_id, %Command{name: :association_group_name_get}, _opts) do
    # Always just return the lifeline group (group_id == 1) as of right now
    # because that is all that Grizzly supports right now.
    case AssociationGroupNameReport.new(group_id: 1, name: "Lifeline") do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(_node_id, %Command{name: :association_group_info_get} = command, _opts) do
    {:ok, report} =
      AssociationGroupInfoReport.new(
        dynamic: false,
        groups_info: [[group_id: 1, profile: :general_lifeline]],
        list_mode: Command.param(command, :all, false)
      )

    [{:send, report}]
  end

  defp handle_command(_node_id, %Command{name: :association_group_command_list_get}, _opts) do
    {:ok, report} =
      AssociationGroupCommandListReport.new(
        group_id: 0x01,
        commands: [:device_reset_locally_notification]
      )

    [{:send, report}]
  end

  defp handle_command(_node_id, %Command{name: :multi_channel_association_groupings_get}, _opts) do
    {:ok, report} = MultiChannelAssociationGroupingsReport.new(supported_groupings: 1)

    [{:send, report}]
  end

  defp handle_command(_node_id, %Command{name: :multi_channel_association_get}, opts) do
    # According the the Z-Wave specification if a get request contains an
    # unsupported grouping identifier then we should report back the grouping
    # information for group number 1. Since right now we only support that
    # group we don't need to check because we will always just send back the
    # grouping information for group id 1.
    associations_server = Keyword.get(opts, :associations_server, Associations)

    {:ok, respond_with_command} =
      case Associations.get(associations_server, 1) do
        nil ->
          MultiChannelAssociationReport.new(
            grouping_identifier: 1,
            max_nodes_supported: 1,
            nodes: [],
            reports_to_follow: 0,
            node_endpoints: []
          )

        association ->
          {endpoints, nodes} = Enum.split_with(association.node_ids, fn v -> is_tuple(v) end)

          MultiChannelAssociationReport.new(
            grouping_identifier: association.grouping_id,
            max_nodes_supported: 1,
            nodes: nodes,
            reports_to_follow: 0,
            node_endpoints:
              Enum.map(endpoints, fn {node, endpoint} ->
                [node: node, endpoint: endpoint, bit_address: 0]
              end)
          )
      end

    [{:send, respond_with_command}]
  end

  defp handle_command(_node_id, %Command{name: :multi_channel_association_set} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)
      node_endpoints = Command.param!(command, :node_endpoints)

      node_endpoints =
        Enum.map(node_endpoints, fn ep ->
          {ep[:node], ep[:endpoint]}
        end)

      case Associations.save(associations_server, grouping_identifier, node_endpoints ++ nodes) do
        :ok -> [supervision_status: :success]
        _ -> [supervision_status: :fail]
      end
    else
      [supervision_status: :fail]
    end
  end

  defp handle_command(_node_id, %Command{name: :multi_channel_association_remove} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_id = Command.param!(command, :grouping_identifier)
    nodes = Command.param!(command, :nodes)
    node_endpoints = Command.param!(command, :node_endpoints)

    node_endpoints =
      Enum.map(node_endpoints, fn ep ->
        {ep[:node], ep[:endpoint]}
      end)

    # This case matching is based off a table from the Z-Wave specification
    # Right now we only have one association grouping, so the first and third
    # match are the same right now. I want to keep the matching explicit right
    # now as I hope it will enable quicker understand to any future work that
    # will be as it maps nicely to the documentation found in the Z-Wave
    # specification.
    case {grouping_id, nodes} do
      {1, []} ->
        :ok = Associations.delete_all_nodes_from_grouping(associations_server, grouping_id)
        []

      {1, nodes} ->
        case Associations.delete_nodes_from_grouping(
               associations_server,
               grouping_id,
               node_endpoints ++ nodes
             ) do
          :ok -> []
          error -> error
        end

      {0, []} ->
        :ok = Associations.delete_all(associations_server)
        []

      {0, nodes} ->
        :ok =
          Associations.delete_nodes_from_all_groupings(
            associations_server,
            node_endpoints ++ nodes
          )

        []

      _ ->
        []
    end
  end

  defp handle_command(node_id, %Command{name: :multi_command_encapsulated} = command, opts) do
    commands = Command.param!(command, :commands)

    extra_commands = [
      :supervision_get,
      :association_group_command_list_get,
      :association_group_name_get,
      :association_group_info_get,
      :association_get,
      :association_set,
      :association_remove,
      :association_groupings_get,
      :association_specific_group_get,
      :multi_channel_association_groupings_get,
      :multi_channel_association_set,
      :multi_channel_association_get,
      :multi_channel_association_remove
    ]

    Enum.reduce(commands, [], fn cmd, actions ->
      if Enum.member?(extra_commands, cmd) do
        new_actions = handle_command(node_id, cmd, opts)
        actions ++ new_actions
      else
        if cmd.name == :alarm_report do
          actions ++ [{:notify, cmd}]
        else
          actions ++ [{:forward_to_controller, cmd}]
        end
      end
    end)
  end

  defp handle_command(_node_id, %Command{name: :version_command_class_get} = command, _opts) do
    command_class = Command.param!(command, :command_class)

    case VersionReports.version_report_for(command_class) do
      {:ok, report} ->
        [{:send, report}]

      _ ->
        []
    end
  end

  defp handle_command(_node_id, %Command{name: :s2_resynchronization_event} = command, _opts) do
    node_id = Command.param!(command, :node_id)
    reason = Command.param!(command, :reason)

    :telemetry.execute(
      [:grizzly, :zwave, :s2_resynchronization],
      %{},
      %{node_id: node_id, reason: reason}
    )

    [{:notify, command}]
  end

  defp handle_command(_node_id, command, _opts), do: [{:notify, command}]

  defp make_supervision_report(%Command{name: :supervision_get} = command, status) do
    session_id = Command.param!(command, :session_id)

    SupervisionReport.new(
      session_id: session_id,
      status: status,
      more_status_updates: :last_report,
      duration: 0
    )
  end
end
