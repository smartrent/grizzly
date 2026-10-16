defmodule Grizzly.Backends.ZwrapTest do
  use ExUnit.Case, async: false

  alias Grizzly.Backends.Zwrap, as: Backend
  alias Grizzly.Backends.Zwrap.Management
  alias Grizzly.Connections.AsyncConnection
  alias Grizzly.Report
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DSK
  alias GrizzlyTest.ZwrapAPI, as: API

  @moduletag skip: Grizzly.Backend.name() != :zwrap

  setup do
    Supervisor.stop(Grizzly.Supervisor)

    associations =
      Path.join(System.tmp_dir!(), "grizzly-zwrap-assoc-#{System.unique_integer([:positive])}")

    opts =
      Keyword.merge(GrizzlyTest.Utils.default_options_args(),
        backend: :zwrap,
        associations_file: associations,
        serial_port: "/dev/test-controller",
        inclusion_handler: self(),
        zwrap_options: [api: API, owner: self()]
      )

    {:ok, supervisor} = Grizzly.Supervisor.start_link(opts)
    Process.unlink(supervisor)

    on_exit(fn ->
      File.rm(associations)
      if pid = Process.whereis(Grizzly.Supervisor), do: Supervisor.stop(pid)

      {:ok, pid} =
        Grizzly.Supervisor.start_link(
          Keyword.put(GrizzlyTest.Utils.default_options_args(), :zwrap_options,
            api: GrizzlyTest.ZwrapAPI,
            owner: self()
          )
        )

      Process.unlink(pid)
    end)

    %{controller: Backend.controller()}
  end

  test "backend selection bypasses gateway, sockets and readiness polling" do
    assert Grizzly.options().backend == :zwrap
    assert Grizzly.ready?()
    assert_receive {:zwrap_started, opts}
    assert opts[:serial_port] == "/dev/test-controller"
    assert Process.whereis(Grizzly.ZIPGateway.Supervisor) == nil
    assert Process.whereis(Grizzly.ZIPGateway.ReadyChecker) == nil
    assert Process.whereis(Grizzly.UnsolicitedServer) == nil
    assert Grizzly.Options.new().backend == :zwrap
    assert_raise ArgumentError, fn -> Grizzly.Options.new(backend: :unknown) end
  end

  test "SET uses raw command-class bytes and native TX completion", %{controller: c} do
    task =
      Task.async(fn ->
        Grizzly.send_command(2, :switch_binary_set, [target_value: :on], transmission_stats: true)
      end)

    assert_receive {:native_call, :send_data_appl, [2, <<0x25, 1, _::binary>>, context]}

    API.emit(c, :send_data_appl_complete, %{
      context: context,
      status: :ok,
      tx_report: %{transmit_ticks: 7}
    })

    assert {:ok, %Report{type: :ack_response, acknowledged: true, transmission_stats: stats}} =
             Task.await(task)

    assert stats[:native_tx_report] == %{transmit_ticks: 7}
  end

  test "native pipeline observations stay separate from overlapping host counters", %{
    controller: c
  } do
    alias Grizzly.Backends.Zwrap.Statistics

    Grizzly.subscribe(:native_event)

    fields = %{
      coverage: :application_pipeline,
      id: 1,
      node_id: 3000,
      source_node_id: 7,
      source_endpoint: 12,
      destination_endpoint: 127,
      frame_length: 3,
      requested_security_scheme: 0xFE
    }

    for stage <- [:queued, :started, :abort_requested] do
      API.emit(c, :tx_observation, Map.merge(fields, %{stage: stage, status: nil}))
    end

    completed = Map.merge(fields, %{stage: :completed, status: :ok, status_code: 0})
    API.emit(c, :tx_observation, completed)
    assert_receive {:grizzly, :native_event, %{event: :tx_observation, fields: ^completed}}
    assert Backend.ready?()
    stats = Statistics.snapshot()
    assert stats.coverage == :application_only
    assert stats.nodes == %{}
    assert stats.native_tx.coverage == :application_pipeline

    assert %{
             queued: 1,
             started: 1,
             abort_requested: 1,
             tx_success: 1,
             tx_failure: 0,
             cancelled_queued: 0,
             last_tx: ^completed
           } = stats.native_tx.nodes[3000]

    # Active abort intent did not count as a confirmed cancellation or failure.
    Statistics.record(3000, :tx_success)
    Statistics.record_native(Map.merge(fields, %{id: 2, stage: :cancelled_queued}))
    Statistics.record_native(Map.merge(fields, %{id: 3, stage: :completed, status: :no_ack}))
    assert %{tx_success: 1} = Statistics.snapshot().nodes[3000]

    assert %{tx_success: 1, tx_failure: 1, cancelled_queued: 1} =
             Statistics.snapshot().native_tx.nodes[3000]

    Statistics.reset()
    assert Statistics.snapshot().native_tx.nodes == %{}
    assert Statistics.snapshot().nodes == %{}
  end

  test "GET waits for decoded report rather than completing on TX ACK", %{controller: c} do
    task = Task.async(fn -> Grizzly.send_command(2, :switch_binary_get) end)
    assert_receive {:native_call, :send_data_appl, [2, <<0x25, 2>>, context]}
    API.emit(c, :send_data_appl_complete, %{context: context, status: :verified})
    assert Task.yield(task, 20) == nil
    frame(c, 2, <<0x25, 3, 0xFF>>)

    assert {:ok,
            %Report{type: :command, command: %{name: :switch_binary_report}, acknowledged: true}} =
             Task.await(task)
  end

  test "native failure retries once, stale callbacks cannot acknowledge a retry", %{controller: c} do
    task =
      Task.async(fn ->
        Grizzly.send_command(2, :switch_binary_set, [target_value: :off], retries: 1)
      end)

    assert_receive {:native_call, :send_data_appl, [2, _, first]}
    API.emit(c, :send_data_appl_complete, %{context: first, status: :no_ack})
    assert_receive {:native_call, :send_data_appl, [2, _, second]}
    assert first != second
    API.emit(c, :send_data_appl_complete, %{context: first, status: :ok})
    assert Task.yield(task, 20) == nil
    API.emit(c, :send_data_appl_complete, %{context: second, status: :fail})
    assert {:error, :nack_response} = Task.await(task)
  end

  test "queue rejection and timeout clean up requests", %{controller: c} do
    API.result(c, {:error, :queue_full})
    assert {:error, :queue_full} = Grizzly.send_command(2, :switch_binary_get)
    API.result(c, :ok)

    assert {:ok, %Report{type: :timeout}} =
             Grizzly.send_command(2, :switch_binary_get, [], timeout: 10)

    assert Backend.ready?()
  end

  test "async references support cancellation", %{controller: c} do
    assert {:ok, %Report{command_ref: ref}} =
             Grizzly.send_command(2, :switch_binary_get, [], mode: :async)

    assert_receive {:native_call, :send_data_appl, [2, _, context]}
    assert AsyncConnection.request_alive?(2, ref)
    assert :ok = AsyncConnection.stop_command(2, ref)
    refute AsyncConnection.request_alive?(2, ref)
    API.emit(c, :send_data_appl_complete, %{context: context, status: :ok})
    refute_receive {:grizzly, :report, %Report{command_ref: ^ref}}
  end

  test "concurrent sync and async requests receive a matching report only once", %{controller: c} do
    sync = Task.async(fn -> Grizzly.send_command(2, :battery_get) end)
    assert_receive {:native_call, :send_data_appl, [2, _, _]}

    assert {:ok, %Report{command_ref: ref}} =
             Grizzly.send_command(2, :switch_binary_get, [], mode: :async)

    assert_receive {:native_call, :send_data_appl, [2, _, _]}
    frame(c, 2, <<0x25, 3, 0xFF>>)

    assert_receive {:grizzly, :report,
                    %Report{command_ref: ^ref, command: %{name: :switch_binary_report}}}

    frame(c, 2, <<0x80, 3, 80>>)
    assert {:ok, %Report{command: %{name: :battery_report}}} = Task.await(sync)
  end

  test "destination endpoint uses Multi Channel, not Z/IP encapsulation", %{controller: c} do
    task = Task.async(fn -> Grizzly.send_command(2, :switch_binary_get, [], destination: 3) end)
    assert_receive {:native_call, :send_data_appl, [2, <<0x60, 0x0D, 0, 3, 0x25, 2>>, _]}
    frame(c, 2, <<0x25, 3, 0xFF>>, 3)
    assert {:ok, %Report{type: :command}} = Task.await(task)
  end

  test "supervision handlers and encapsulation are reused", %{controller: c} do
    task =
      Task.async(fn ->
        Grizzly.send_command(2, :switch_binary_set, [target_value: :on], supervision?: true)
      end)

    assert_receive {:native_call, :send_data_appl,
                    [2, <<0x6C, 1, properties, _::binary>>, context]}

    API.emit(c, :send_data_appl_complete, %{context: context, status: :ok})
    session = Bitwise.band(properties, 0x3F)
    frame(c, 2, <<0x6C, 2, session, 0xFF, 0>>)
    assert {:ok, %Report{command: %{name: :supervision_report}}} = Task.await(task)
  end

  test "unsolicited frames use existing event handling and generate raw supervision replies", %{
    controller: c
  } do
    Grizzly.subscribe(:battery_report)
    frame(c, 2, <<0x80, 3, 50>>)

    assert_receive {:grizzly, :report,
                    %Report{type: :unsolicited, node_id: 2, command: %{name: :battery_report}}}

    frame(c, 2, <<0x6C, 1, 1, 3, 0x80, 3, 51>>)
    assert_receive {:grizzly, :report, %Report{type: :unsolicited}}
    assert_receive {:native_call, :send_data_appl, [2, <<0x6C, 2, _::binary>>, nil]}
    frame(c, 2, <<0x6C, 1, 2, 3, 0x80, 3, 52>>, 3)

    assert_receive {:native_call, :send_data_appl,
                    [2, <<0x60, 0x0D, 0, 3, 0x6C, 2, _::binary>>, nil]}
  end

  test "S2 inclusion preserves Grizzly's user interaction flow", %{controller: c} do
    assert :ok = Grizzly.Inclusions.add_node()
    assert_receive {:native_call, :start_secure_inclusion, []}
    API.emit(c, :inclusion_keys_report, %{request_csa: false, requested_keys_mask: 4})
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_keys_report}}}
    assert :ok = Grizzly.Inclusions.grant_keys([:s2_access_control])
    assert_receive {:native_call, :grant_inclusion_keys, [[:s2_access], [csa: false]]}
    API.emit(c, :inclusion_dsk_report, %{reserved_dsk_len: 2, dsk: <<0::128>>})
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_dsk_report}}}
    assert :ok = Grizzly.Inclusions.set_input_dsk(DSK.new(<<12345::16, 0::112>>))
    assert_receive {:native_call, :accept_authenticated_dsk, [12345]}

    API.emit(c, :inclusion_status, %{
      status: :done,
      result: :success,
      node_id: 2,
      properties1: 0x80,
      properties2: 0,
      basic_device_class: 4,
      generic_device_class: 16,
      specific_device_class: 1,
      command_class_bytes: <<0x25>>
    })

    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_status} = cmd}}
    assert Command.param!(cmd, :node_id) == 2
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
  end

  test "abort stops logical inclusion and exclusion without leaving timers", %{controller: c} do
    assert :ok = Grizzly.Inclusions.add_node()
    assert :ok = Grizzly.Inclusions.add_node_stop()
    assert_receive {:native_call, :abort_inclusion, []}
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_status}}}
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
    assert :ok = Grizzly.Inclusions.remove_node()
    assert_receive {:native_call, :start_exclusion, []}
    API.emit(c, :node_remove_status, %{result: :success, node_id: 2})
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_remove_status}}}
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
  end

  test "controller reset, failed removal and provisioning map back to command reports", %{
    controller: c
  } do
    task = Task.async(fn -> Grizzly.Network.reset_controller(notify: false) end)
    assert_receive {:native_call, :set_default, []}
    API.emit(c, :set_default, %{result: :success, home_id: <<1, 2, 3, 4>>})
    assert {:ok, %Report{command: %{name: :default_set_complete}}} = Task.await(task)
    task = Task.async(fn -> Grizzly.Network.remove_failed_node(node_id: 300) end)
    assert_receive {:native_call, :remove_failed_node, [300]}
    API.emit(c, :failed_node_remove_status, %{result: :success, node_id: 300})
    assert {:ok, %Report{command: %{name: :failed_node_remove_status}}} = Task.await(task)
    dsk = DSK.new(<<1::128>>)
    assert {:ok, %Report{type: :ack_response}} = Grizzly.Network.set_node_provisioning(dsk, [])
    assert_receive {:native_call, :add_provision, [raw, <<>>]}
    task = Task.async(fn -> Grizzly.Network.get_node_provisioning(dsk) end)
    assert_receive {:native_call, :get_provision, [^raw]}
    API.emit(c, :provision_report, %{dsk: raw, dsk_length: 16})
    assert {:ok, %Report{command: %{name: :node_provisioning_report}}} = Task.await(task)
  end

  test "unsupported operations return errors, never fall back to ZIP", %{controller: _c} do
    assert {:error, :unsupported_backend_operation} = Grizzly.send_binary(2, <<0, 1>>)

    assert {:error, :unsupported_backend_command} =
             Grizzly.send_command(:gateway, :node_list_get, seq_number: 1)

    assert {:error, :unsupported_backend_command} = Grizzly.Inclusions.learn_mode()
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
    assert Backend.ready?()
  end

  test "native controller death releases pending synchronous callers", %{controller: c} do
    task = Task.async(fn -> Grizzly.send_command(2, :switch_binary_get) end)
    assert_receive {:native_call, :send_data_appl, _}
    Process.exit(c, :kill)
    assert {:error, :backend_down} = Task.await(task)
    assert_receive {:zwrap_started, _}
  end

  test "context-free operations remain reserved after client timeout", %{controller: c} do
    assert {:ok, command} = Commands.create(:default_set, seq_number: 1)
    {:ok, _} = Grizzly.Connection.open(:gateway)

    assert {:ok, %Report{type: :timeout}} =
             Grizzly.Connection.send_command(:gateway, command, timeout: 10)

    assert_receive {:native_call, :set_default, []}
    assert {:error, :busy} = Grizzly.Connection.send_command(:gateway, command, timeout: 10)
    API.emit(c, :set_default, %{result: :success, home_id: <<0::32>>})
    assert Backend.ready?()
    task = Task.async(fn -> Grizzly.Connection.send_command(:gateway, command) end)
    assert_receive {:native_call, :set_default, []}
    API.emit(c, :set_default, %{result: :success, home_id: <<0::32>>})
    assert {:ok, %Report{type: :command}} = Task.await(task)
  end

  test "unsecure inclusion, unauthenticated DSK and exclusion abort use native calls", %{
    controller: c
  } do
    assert :ok = Grizzly.Inclusions.add_node(mode: :node_add_any)
    assert_receive {:native_call, :start_unsecure_inclusion, []}
    API.emit(c, :inclusion_dsk_report, %{reserved_dsk_len: 0, dsk: <<0::128>>})
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_dsk_report}}}
    assert :ok = Grizzly.Inclusions.set_input_dsk(DSK.new(<<0::128>>))
    assert_receive {:native_call, :accept_unauthenticated_dsk, []}
    assert :ok = Grizzly.Inclusions.add_node_stop()
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_status}}}
    :sys.get_state(Grizzly.InclusionServer)
    assert :ok = Grizzly.Inclusions.remove_node()
    assert :ok = Grizzly.Inclusions.remove_node_stop()
    assert_receive {:native_call, :abort_exclusion, []}
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_remove_status}}}
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
  end

  test "rejecting S2 grants aborts the native inclusion and completes its original request", %{
    controller: _c
  } do
    assert :ok = Grizzly.Inclusions.add_node()

    command =
      Commands.create!(:node_add_keys_set,
        seq_number: 1,
        accept: false,
        csa: false,
        granted_keys: []
      )

    assert {:ok, _ref} = AsyncConnection.send_command(1, command)
    assert_receive {:native_call, :abort_inclusion, []}
    assert_receive {:grizzly, :report, %Report{command: %{name: :node_add_status}}}
    :sys.get_state(Grizzly.InclusionServer)
    assert Grizzly.inclusion_status() == :idle
  end

  test "provisioning delete-all and iteration preserve DSK and remaining count", %{controller: c} do
    assert {:ok, %Report{type: :ack_response}} = Grizzly.Network.delete_node_provisioning(nil)
    assert_receive {:native_call, :delete_provision, [<<>>]}
    task = Task.async(fn -> Grizzly.Network.list_node_provisionings(255) end)
    assert_receive {:native_call, :iter_get_provision, [seq, 255]}

    API.emit(c, :provision_iter_report, %{
      seq_no: seq,
      remaining: 0,
      dsk: <<1::128>>,
      dsk_length: 16
    })

    assert {:ok, %Report{command: %{name: :node_provisioning_list_iteration_report} = command}} =
             Task.await(task)

    assert Command.param!(command, :remaining_count) == 0
    assert Command.param!(command, :meta_extensions) == []
  end

  test "ZIPGateway helpers and nondefault native options fail explicitly" do
    assert {:error, :unsupported_backend_operation} = Grizzly.start_zipgateway()
    assert {:error, :unsupported_backend_operation} = Grizzly.restart_zipgateway()
    assert {:error, :unsupported_backend_operation} = Grizzly.stop_zipgateway()
    assert nil == Grizzly.listening_mode(2)
    refute Grizzly.zipgateway_ready?()

    assert {:error, :unsupported_backend_operation} =
             Grizzly.send_command(2, :node_list_get, seq_number: 1)

    assert {:error, :unsupported_backend_operation} =
             Grizzly.Inclusions.add_node(controller_id: 2)

    assert {:error, :unsupported_backend_option} = Grizzly.Inclusions.add_node(tx_opt: :low_power)

    assert_raise ArgumentError, fn ->
      Grizzly.Options.new(backend: :zwrap, zwave_firmware: %{enabled: true})
    end
  end

  test "closing a request session releases pending synchronous waiters" do
    task = Task.async(fn -> Grizzly.send_command(2, :switch_binary_get) end)
    assert_receive {:native_call, :send_data_appl, _}
    Grizzly.Connection.close(2)
    assert {:error, :backend_down} = Task.await(task)
  end

  test "all rejected local commands are explicitly named in the unsupported inventory" do
    supported = [
      :node_add,
      :node_remove,
      :node_add_keys_set,
      :node_add_dsk_set,
      :default_set,
      :failed_node_remove,
      :node_provisioning_set,
      :node_provisioning_delete,
      :node_provisioning_get,
      :node_provisioning_list_iteration_get
    ]

    inventory = File.read!(Path.expand("../docs/zwrap-unsupported.md", __DIR__))

    for {name, spec} <- Commands.builtin_commands(),
        Management.local?(%{command_class: spec.command_class}),
        name not in supported do
      assert inventory =~ "`#{name}`", "missing unsupported operation #{name}"
    end
  end

  test "malformed/unknown incoming frames cannot terminate the controller", %{controller: c} do
    frame(c, 2, <<0x25, 3>>)
    frame(c, 2, <<0xFF, 0xFE>>)
    frame(c, 2, <<>>)
    assert Backend.ready?()
  end

  defp frame(controller, node_id, frame, endpoint \\ 0) do
    API.emit(controller, :unsolicited_frame_received, %{
      node_id: node_id,
      frame: frame,
      source_endpoint: endpoint,
      destination_endpoint: 0
    })
  end

  test "more_info is Elixir awake policy rather than a rejected ZIP option", %{controller: c} do
    task =
      Task.async(fn ->
        Grizzly.send_command(2, :switch_binary_set, [target_value: :on], more_info: true)
      end)

    assert_receive {:native_call, :send_data_appl, [2, _, context]}
    API.emit(c, :send_data_appl_complete, %{context: context, status: :ok})
    assert {:ok, %Report{type: :ack_response}} = Task.await(task)
  end

  test "unmatched firmware requests reach only an opted-in async session", %{controller: c} do
    {:ok, conn} =
      Grizzly.Connection.open(2,
        mode: :async,
        unnamed: true,
        session_commands: [:firmware_update_md_get]
      )

    command = Commands.create!(:firmware_update_md_get, number_of_reports: 1, report_number: 1)

    API.emit(c, :unsolicited_frame_received, %{
      node_id: 2,
      frame: Grizzly.ZWave.to_binary(command)
    })

    assert_receive {:grizzly, :report,
                    %Report{command: %{name: :firmware_update_md_get}, command_ref: nil}}

    refute_receive {:grizzly, :report, %Report{command: %{name: :firmware_update_md_get}}}
    GenServer.stop(conn)
  end

  test "native Home ID and key inspection do not depend on log scraping", %{controller: c} do
    assert Grizzly.home_id() == "01020304"
    assert Grizzly.network_keys() == []
    assert Grizzly.zniffer_network_keys() == nil

    keys = %{
      assigned_key_mask: 0x9F,
      s0: <<1::128>>,
      s2_unauthenticated: <<2::128>>,
      s2_authenticated: <<3::128>>,
      s2_access: <<4::128>>,
      s2_authenticated_lr: <<5::128>>,
      s2_access_lr: <<6::128>>
    }

    API.keys(c, keys)
    Grizzly.subscribe(:native_event)
    exported = Grizzly.network_keys()
    assert exported[:s0] == Base.encode16(<<1::128>>)
    assert exported[:s2_access_control_long_range] == Base.encode16(<<6::128>>)
    assert length(exported) == 6
    text = Grizzly.zniffer_network_keys()
    assert text =~ "01020304.txt:"
    assert text =~ "9F;#{Base.encode16(<<6::128>>)};1"
    refute_receive {:grizzly, :native_event, _}
    API.keys(c, %{keys | assigned_key_mask: 0x80})
    assert Grizzly.network_keys() == [s0: Base.encode16(<<1::128>>)]
    assert Grizzly.zniffer_network_keys() == nil
  end

  test "top-level native settings are normalized and forwarded without nil shadowing" do
    assert_receive {:zwrap_started, _}
    Supervisor.stop(Grizzly.Supervisor)

    opts =
      Keyword.merge(GrizzlyTest.Utils.default_options_args(),
        rf_region: :us,
        power_level: {-5, 6},
        manufacturer_id: 0x1234,
        product_type: 0x4321,
        product_id: 0xABCD,
        hardware_version: 9,
        zwrap_options: [api: API, owner: self(), rf_region: nil]
      )

    {:ok, supervisor} = Grizzly.Supervisor.start_link(opts)
    Process.unlink(supervisor)
    assert_receive {:zwrap_started, settings}
    assert settings[:rf_region] == 1
    assert settings[:power_level] == {-5, 6}
    assert settings[:manufacturer_id] == 0x1234
    assert settings[:product_type] == 0x4321
    assert settings[:product_id] == 0xABCD
    assert settings[:hardware_version] == 9
  end

  test "conflicting nested settings fail before the native controller starts" do
    assert_receive {:zwrap_started, _}
    Supervisor.stop(Grizzly.Supervisor)

    opts =
      Keyword.merge(GrizzlyTest.Utils.default_options_args(),
        rf_region: :us,
        zwrap_options: [api: API, owner: self(), rf_region: :eu]
      )

    task =
      Task.async(fn ->
        Process.flag(:trap_exit, true)
        Grizzly.Supervisor.start_link(opts)
      end)

    assert {:error, reason} = Task.await(task)
    assert inspect(reason) =~ "conflicting Grizzly/Zwrap initialization setting"
    refute_receive {:zwrap_started, _}
  end
end
