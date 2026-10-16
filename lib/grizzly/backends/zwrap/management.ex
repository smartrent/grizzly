defmodule Grizzly.Backends.Zwrap.Management do
  @moduledoc false

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion, as: NMI
  alias Grizzly.ZWave.CommandClasses.NodeProvisioning
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NodeInformationSend
  alias Grizzly.ZWave.DSK
  alias Grizzly.ZWave.Security
  alias Grizzly.ZWave.SmartStart.MetaExtension

  def local?(command) do
    command.command_class in [
      :network_management_inclusion,
      :network_management_basic_node,
      :network_management_proxy,
      :network_management_installation_maintenance,
      :node_provisioning,
      :zip_gateway,
      :zip,
      :zip_nd
    ]
  end

  def submit(state, entry) do
    if Command.param(entry.command, :tx_opt, :explore) != :explore do
      {:error, :unsupported_backend_option}
    else
      dispatch(entry.command.name, state, entry)
    end
  rescue
    _error in [ArgumentError, FunctionClauseError, MatchError, KeyError] ->
      {:error, :invalid_backend_argument}
  end

  defp dispatch(:node_add, state, entry) do
    case Command.param(entry.command, :mode, :node_add_s2_any) do
      :node_add_stop ->
        stop_operation(state, entry, :inclusion, :abort_inclusion)

      :node_add_any ->
        begin_operation(state, entry, :inclusion, :start_unsecure_inclusion)

      mode when mode in [:node_add_s2_any, :node_add_any_s2] ->
        begin_operation(state, entry, :inclusion, :start_secure_inclusion)

      _ ->
        {:error, :unsupported_backend_option}
    end
  end

  defp dispatch(:node_remove, state, entry) do
    case Command.param(entry.command, :mode, :remove_node_any) do
      :remove_node_stop -> stop_operation(state, entry, :exclusion, :abort_exclusion)
      :remove_node_any -> begin_operation(state, entry, :exclusion, :start_exclusion)
      _ -> {:error, :unsupported_backend_option}
    end
  end

  defp dispatch(:node_add_keys_set, state, entry) do
    if Keyword.get(entry.command.params, :accept, true) do
      keys = Command.param!(entry.command, :granted_keys)

      keys =
        Enum.map(keys, fn
          :s2_access_control -> :s2_access
          key -> key
        end)

      accept(state, entry, :grant_inclusion_keys, [
        keys,
        [csa: Keyword.get(entry.command.params, :csa, false)]
      ])
    else
      reject_inclusion(state, entry)
    end
  end

  defp dispatch(:node_add_dsk_set, state, entry) do
    cond do
      not Keyword.get(entry.command.params, :accept, true) ->
        reject_inclusion(state, entry)

      Command.param(entry.command, :input_dsk_length, 0) == 0 ->
        accept(state, entry, :accept_unauthenticated_dsk, [])

      Command.param(entry.command, :input_dsk_length, 0) == 2 ->
        <<fragment::16, _::binary>> = dsk_binary(Command.param!(entry.command, :input_dsk))
        accept(state, entry, :accept_authenticated_dsk, [fragment])

      true ->
        {:error, :unsupported_backend_option}
    end
  end

  defp dispatch(:default_set, state, entry),
    do: begin_operation(state, entry, :reset, :set_default)

  defp dispatch(:failed_node_remove, state, entry) do
    begin_operation(state, entry, :failed_remove, :remove_failed_node, [
      Command.param!(entry.command, :node_id)
    ])
  end

  defp dispatch(:node_provisioning_set, state, entry) do
    tlv =
      NodeProvisioning.encode_meta_extensions(Command.param(entry.command, :meta_extensions, []))

    accept(state, entry, :add_provision, [dsk_binary(Command.param!(entry.command, :dsk)), tlv])
  end

  defp dispatch(:node_provisioning_delete, state, entry) do
    accept(state, entry, :delete_provision, [dsk_binary(Command.param(entry.command, :dsk))])
  end

  defp dispatch(:node_provisioning_get, state, entry) do
    begin_operation(state, entry, :provision, :get_provision, [
      dsk_binary(Command.param!(entry.command, :dsk))
    ])
  end

  defp dispatch(:node_provisioning_list_iteration_get, state, entry) do
    begin_operation(state, entry, :provision_iteration, :iter_get_provision, [
      seq(entry),
      Command.param!(entry.command, :remaining_counter)
    ])
  end

  defp dispatch(:dsk_get, state, entry) do
    with {:ok, dsk} <-
           state.api.control(state.controller, :public_dsk,
             a: if(Command.param!(entry.command, :add_mode) == :add, do: 1, else: 0)
           ) do
      report(state, entry, :dsk_report,
        add_mode: Command.param!(entry.command, :add_mode),
        dsk: DSK.new(dsk)
      )
    end
  end

  defp dispatch(:network_update_request, state, entry),
    do: radio_operation(state, entry, :network_update, :network_update, [])

  defp dispatch(:node_neighbor_update_request, state, entry),
    do:
      radio_operation(state, entry, :neighbor_update, :neighbor_update,
        a: Command.param!(entry.command, :node_id)
      )

  defp dispatch(:node_information_send, state, entry) do
    <<_seq, _reserved, destination, tx_options>> =
      NodeInformationSend.encode_params(nil, entry.command)

    radio_operation(state, entry, :nif, :send_nif, a: destination, b: tx_options)
  end

  defp dispatch(_name, _state, _entry), do: {:error, :unsupported_backend_command}

  defp radio_operation(state, entry, key, operation, opts) do
    if map_size(state.operations) != 0 do
      {:error, :busy}
    else
      with {:ok, <<>>} <- state.api.control(state.controller, operation, opts) do
        {:ok, put_in(state.operations[key], entry)}
      end
    end
  end

  defp report(state, entry, name, params) do
    with {:ok, command} <- Commands.create(name, [seq_number: seq(entry)] ++ params) do
      send(entry.pid, {:backend_report, entry.ref, command})
      {:ok, state}
    end
  end

  def handle_event(state, :control_complete, %{operation: 4} = fields) do
    if entry = state.operations[:nif] do
      if fields.result == :success,
        do: send(entry.pid, {:backend_ack, entry.ref, entry.attempt, nil}),
        else: send(entry.pid, {:backend_rejected, entry.ref, :transmission_failed})
    end

    %{state | operations: Map.delete(state.operations, :nif)}
  end

  def handle_event(state, :network_update_request_status, fields),
    do:
      finish(state, :network_update, :network_update_request_status,
        status:
          Map.get(
            %{0 => :done, 1 => :abort, 2 => :wait, 3 => :disabled, 4 => :overflow},
            fields[:status_code],
            if(fields.result == :success, do: :done, else: :abort)
          )
      )

  def handle_event(state, :node_neighbor_update_status, fields),
    do:
      finish(state, :neighbor_update, :node_neighbor_update_status,
        status: if(fields.result == :success, do: :done, else: :failed)
      )

  def handle_event(state, :inclusion_keys_report, fields) do
    intermediate(state, :node_add_keys_report,
      csa: fields.request_csa,
      requested_keys: Security.byte_to_keys(fields.requested_keys_mask)
    )
  end

  def handle_event(state, :inclusion_dsk_report, fields) do
    intermediate(state, :node_add_dsk_report,
      input_dsk_length: fields.reserved_dsk_len,
      dsk: NodeProvisioning.optional_binary_to_dsk(fields.dsk)
    )
  end

  def handle_event(state, :inclusion_status, fields) do
    if fields.status in [
         :done,
         :failed,
         :security_failed,
         :interview_done,
         :not_primary,
         :success,
         :error
       ] do
      status =
        case fields.status do
          s when s in [:done, :interview_done, :success] -> :done
          :security_failed -> :security_failed
          _ -> :failed
        end

      classes = fields[:command_class_bytes] || <<>>

      info =
        NMI.parse_node_info(
          <<byte_size(classes) + 6, fields[:properties1] || 0, fields[:properties2] || 0,
            fields[:basic_device_class] || 0, fields[:generic_device_class] || 0,
            fields[:specific_device_class] || 0, classes::binary>>
        )

      finish(
        state,
        :inclusion,
        :node_add_status,
        [status: status, node_id: fields.node_id] ++ Map.to_list(info)
      )
    else
      state
    end
  end

  def handle_event(state, :node_remove_status, fields) do
    finish(state, :exclusion, :node_remove_status,
      status: if(fields.result == :success, do: :done, else: :failed),
      node_id: fields.node_id
    )
  end

  def handle_event(state, :failed_node_remove_status, fields) do
    finish(state, :failed_remove, :failed_node_remove_status,
      status: if(fields.result == :success, do: :done, else: :failed_node_remove_fail),
      node_id: fields.node_id
    )
  end

  def handle_event(state, :set_default, fields) do
    finish(state, :reset, :default_set_complete,
      status: if(fields.result == :success, do: :done, else: :busy)
    )
  end

  def handle_event(state, :provision_report, fields) do
    finish(state, :provision, :node_provisioning_report,
      dsk: NodeProvisioning.optional_binary_to_dsk(fields.dsk),
      meta_extensions: MetaExtension.parse(fields[:tlv] || <<>>)
    )
  end

  def handle_event(state, :provision_iter_report, fields) do
    finish(state, :provision_iteration, :node_provisioning_list_iteration_report,
      dsk: NodeProvisioning.optional_binary_to_dsk(fields.dsk),
      remaining_count: fields.remaining,
      meta_extensions: MetaExtension.parse(fields[:tlv] || <<>>)
    )
  end

  def handle_event(state, _event, _fields), do: state

  defp begin_operation(state, entry, key, function, args \\ []) do
    # Core management callbacks have no opaque context. Do not allow overlapping
    # operations of the same type, or a final event could complete the wrong call.
    if Map.has_key?(state.operations, key) or
         (key in [:inclusion, :exclusion] and
            Enum.any?([:inclusion, :exclusion], &Map.has_key?(state.operations, &1))) do
      {:error, :busy}
    else
      with :ok <- apply(state.api, function, [state.controller | args]) do
        {:ok, put_in(state.operations[key], entry)}
      end
    end
  end

  defp stop_operation(state, entry, key, function) do
    with :ok <- apply(state.api, function, [state.controller]) do
      if previous = state.operations[key], do: send(previous.pid, {:backend_cancel, previous.ref})
      state = %{state | operations: Map.delete(state.operations, key)}
      # Abort has no guaranteed terminal callback. Report acceptance, and clear
      # the inclusion state through the normal status command path immediately.
      name = if key == :inclusion, do: :node_add_status, else: :node_remove_status

      params =
        if key == :inclusion,
          do: [
            status: :failed,
            node_id: 0,
            listening?: false,
            basic_device_class: :unknown,
            generic_device_class: :unknown,
            specific_device_class: :unknown,
            command_classes: []
          ],
          else: [status: :failed, node_id: 0]

      {:ok, command} = Commands.create(name, [seq_number: seq(entry)] ++ params)
      send(entry.pid, {:backend_report, entry.ref, command})
      {:ok, state}
    end
  end

  defp accept(state, entry, function, args) do
    with :ok <- apply(state.api, function, [state.controller | args]) do
      send(entry.pid, {:backend_ack, entry.ref, entry.attempt, nil})
      {:ok, state}
    end
  end

  defp reject_inclusion(state, entry) do
    with {:ok, state} <- accept(state, entry, :abort_inclusion, []) do
      {:ok,
       finish(state, :inclusion, :node_add_status,
         status: :failed,
         node_id: 0,
         listening?: false,
         basic_device_class: :unknown,
         generic_device_class: :unknown,
         specific_device_class: :unknown,
         command_classes: []
       )}
    end
  end

  defp intermediate(state, name, params) do
    if entry = state.operations[:inclusion] do
      {:ok, command} = Commands.create(name, [seq_number: seq(entry)] ++ params)
      send(entry.pid, {:backend_intermediate, command})
    end

    state
  end

  defp finish(state, key, name, params) do
    if entry = state.operations[key] do
      {:ok, command} = Commands.create(name, [seq_number: seq(entry)] ++ params)
      send(entry.pid, {:backend_report, entry.ref, command})
      %{state | operations: Map.delete(state.operations, key)}
    else
      state
    end
  end

  defp seq(entry), do: Command.param(entry.command, :seq_number, 0)
  defp dsk_binary(pin) when is_integer(pin) and pin in 0..65535, do: <<pin::16>>
  defp dsk_binary(nil), do: <<>>
  defp dsk_binary(%DSK{raw: raw}), do: raw
  defp dsk_binary(binary) when is_binary(binary), do: binary
end
