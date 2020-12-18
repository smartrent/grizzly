defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  # module helper for handling various different responses from the Z-Wave PAN
  # network

  require Logger

  alias Grizzly.{Transport, VersionReports}
  alias Grizzly.{Associations, ZWave}
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationReport,
    AssociationGroupingsReport,
    AssociationGroupNameReport,
    AssociationGroupCommandListReport,
    AssociationGroupInfoReport,
    AssociationSpecificGroupReport,
    MultiChannelAssociationGroupingsReport,
    MultiChannelAssociationReport,
    SupervisionReport
  }

  @type opt() :: {:association_server, GenServer.name()}

  @type action() ::
          {:notify, Command.t()} | {:send, Command.t()} | {:forward_to_controller, Command.t()}

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Transport.Response.t(), [opt()]) :: [action()] | {:error, reason :: any()}
  def handle_response(response, opts \\ []) do
    internal_command = Command.param!(response.command, :command)

    case handle_command(internal_command, opts) do
      {:error, _any} = error ->
        error

      actions when is_list(actions) ->
        actions
    end
  end

  defp handle_command(%Command{name: :supervision_get} = command, _) do
    {:ok, supervision_report} = make_supervision_report(command)
    encapsulated_command = Command.param!(command, :encapsulated_command)

    case ZWave.from_binary(encapsulated_command) do
      {:ok, report} ->
        [{:notify, report}, {:send, supervision_report}]

      {:error, reason} ->
        Logger.warn(
          "Failed to parse: #{inspect(encapsulated_command)} notification for reason: #{
            inspect(reason)
          }"
        )

        []
    end
  end

  defp handle_command(%Command{name: :association_specific_group_get}, _) do
    case AssociationSpecificGroupReport.new(group: 0) do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(%Command{name: :association_get}, opts) do
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

  defp handle_command(%Command{name: :association_set} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)
      :ok = Associations.save(associations_server, grouping_identifier, nodes)
    end

    []
  end

  defp handle_command(%Command{name: :association_groupings_get}, _opts) do
    case AssociationGroupingsReport.new(supported_groupings: 1) do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(%Command{name: :association_remove} = command, opts) do
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

  defp handle_command(%Command{name: :association_group_name_get}, _opts) do
    # Always just return the lifeline group (group_id == 1) as of right now
    # because that is all that Grizzly supports right now.
    case AssociationGroupNameReport.new(group_id: 1, name: "Lifeline") do
      {:ok, command} -> [{:send, command}]
    end
  end

  defp handle_command(%Command{name: :association_group_info_get}, _opts) do
    {:ok, report} =
      AssociationGroupInfoReport.new(
        dynamic: false,
        groups_info: [[group_id: 1, profile: :general_lifeline]]
      )

    [{:send, report}]
  end

  defp handle_command(%Command{name: :association_group_command_list_get}, _opts) do
    {:ok, report} =
      AssociationGroupCommandListReport.new(
        group_id: 0x01,
        commands: [:device_reset_locally_notification]
      )

    [{:send, report}]
  end

  defp handle_command(%Command{name: :multi_channel_association_groupings_get}, _opts) do
    {:ok, report} = MultiChannelAssociationGroupingsReport.new(supported_groupings: 1)

    [{:send, report}]
  end

  defp handle_command(%Command{name: :multi_channel_association_get}, opts) do
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
            nodes: []
          )

        association ->
          MultiChannelAssociationReport.new(
            grouping_identifier: association.grouping_id,
            max_nodes_supported: 1,
            nodes: association.node_ids
          )
      end

    [{:send, respond_with_command}]
  end

  defp handle_command(%Command{name: :multi_channel_association_set} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)
      :ok = Associations.save(associations_server, grouping_identifier, nodes)
    end

    []
  end

  defp handle_command(%Command{name: :multi_channel_association_remove} = command, opts) do
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

  defp handle_command(%Command{name: :multi_command_encapsulated} = command, opts) do
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
        new_actions = handle_command(cmd, opts)
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

  defp handle_command(%Command{name: :version_command_class_get} = command, _opts) do
    command_class = Command.param!(command, :command_class)

    case VersionReports.version_report_for(command_class) do
      {:ok, report} ->
        [{:send, report}]

      _ ->
        []
    end
  end

  defp handle_command(command, _opts), do: [{:notify, command}]

  def make_supervision_report(%Command{name: :supervision_get} = command) do
    session_id = Command.param!(command, :session_id)

    SupervisionReport.new(
      session_id: session_id,
      status: :success,
      more_status_updates: :last_report,
      duration: 0
    )
  end
end
