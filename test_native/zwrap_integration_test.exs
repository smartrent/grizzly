defmodule Grizzly.Backends.ZwrapIntegrationTest do
  use ExUnit.Case, async: false

  alias Grizzly.Backends.Zwrap, as: Backend
  alias Grizzly.Backends.Zwrap.Statistics
  alias Grizzly.Report
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DSK

  @moduletag skip: Grizzly.Backend.name() != :zwrap

  @moduletag :zwrap_integration
  @moduletag timeout: 60_000

  for id <- [1, 7] do
    @tag controller_id: id
    test "Grizzly talks directly through the Rust port to controller #{id}", %{
      controller_id: controller_id
    } do
      core =
        System.get_env("ZWAVE_CORE_ROOT") ||
          Path.expand("../../zipato-zwave-core-parity", __DIR__)

      fake_root = Path.join(core, "tests/integration/fake_ncp")
      python = System.find_executable("python3") || raise "Python 3 required"
      {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
      {:ok, port} = :inet.port(socket)
      :gen_tcp.close(socket)

      fixture_path =
        Path.join(
          System.tmp_dir!(),
          "grizzly-ncp-#{System.pid()}-#{System.unique_integer([:positive])}.json"
        )

      fixture = File.read!(Path.join(fake_root, "fixtures/one_switch.json"))

      fixture =
        Regex.replace(~r/"(controller_node_id|suc_node_id)"\s*:\s*1/, fixture, fn match, _key ->
          String.replace_suffix(match, "1", to_string(controller_id))
        end)

      File.write!(fixture_path, fixture)
      on_exit(fn -> File.rm(fixture_path) end)

      fake =
        Port.open({:spawn_executable, to_charlist(python)}, [
          {:args,
           [
             "-u",
             Path.join(fake_root, "fake_ncp.py"),
             "--fixture",
             fixture_path,
             "--port",
             Integer.to_string(port)
           ]},
          {:line, 4096},
          :binary,
          :exit_status,
          :stderr_to_stdout
        ])

      {:os_pid, os_pid} = Port.info(fake, :os_pid)

      dir =
        Path.join(System.tmp_dir!(), "grizzly-zwrap-native-#{System.unique_integer([:positive])}")

      on_exit(fn ->
        if pid = Process.whereis(Grizzly.Supervisor), do: Supervisor.stop(pid)
        System.cmd("kill", ["-TERM", Integer.to_string(os_pid)], stderr_to_stdout: true)
        File.rm_rf!(dir)

        {:ok, pid} =
          Grizzly.Supervisor.start_link(
            Keyword.put(GrizzlyTest.Utils.default_options_args(), :zwrap_options,
              api: GrizzlyTest.ZwrapAPI,
              owner: self()
            )
          )

        Process.unlink(pid)
      end)

      assert_receive {^fake, {:data, {:eol, "Fake NCP listening on " <> _}}}, 5_000
      Supervisor.stop(Grizzly.Supervisor)

      opts =
        Keyword.merge(GrizzlyTest.Utils.default_options_args(),
          backend: :zwrap,
          serial_port: "tcp://127.0.0.1:#{port}",
          associations_file: Path.join(dir, "associations.etf"),
          zwrap_options: [data_dir: dir, node_probe_autostart_block: true]
        )

      # Associations starts before Zwrap creates data_dir.
      File.mkdir_p!(dir)
      {:ok, supervisor} = Grizzly.Supervisor.start_link(opts)
      Process.unlink(supervisor)
      controller = Backend.controller()
      assert Backend.identity().controller_id == controller_id
      api = Module.concat(["Zwrap"])
      assert Grizzly.ready?()
      assert Process.whereis(Grizzly.UnsolicitedServer) == nil
      Grizzly.subscribe(:native_event)

      assert :ok =
               api.apply_node_interview(controller, %{
                 node_id: 2,
                 endpoints: [%{endpoint_id: 0, endpoint_info: <<16, 1, 0x20, 0x25, 0x72, 0x86>>}]
               })

      assert {:ok, %Report{type: :command, command: %{name: :manufacturer_specific_report}}} =
               Grizzly.send_command(2, :manufacturer_specific_get, [], timeout: 10_000)

      assert {:ok, %Report{type: :ack_response, acknowledged: true}} =
               Grizzly.send_command(2, :switch_binary_set, [target_value: :on], timeout: 10_000)

      assert_receive {:grizzly, :native_event,
                      %{
                        event: :tx_observation,
                        fields: %{
                          source_node_id: ^controller_id,
                          node_id: 2,
                          stage: :completed,
                          status: :ok,
                          coverage: :application_pipeline
                        }
                      }},
                     5_000

      assert {:ok, %Report{type: :ack_response, acknowledged: true}} =
               Grizzly.send_command(
                 :gateway,
                 :node_information_send,
                 [seq_number: 91, destination_node_id: 2, tx_options: [:ack]],
                 timeout: 10_000
               )

      assert_receive {:grizzly, :native_event,
                      %{
                        event: :control_complete,
                        fields: %{operation: 4, node_id: 2, result: :success, status_code: 0}
                      }},
                     5_000

      stats = Statistics.snapshot()
      assert stats.native_tx.nodes[2].tx_success >= 2
      assert stats.nodes[2].tx_success >= 2

      assert {:ok, %Report{type: :command, command: %{name: :version_command_class_report}}} =
               Grizzly.send_command(
                 2,
                 :version_command_class_get,
                 [command_class: :switch_binary],
                 timeout: 10_000
               )

      directory = Grizzly.Backends.Zwrap.Directory
      assert {:ok, %{id: 2}} = directory.get_node(2)
      assert {:error, :controller_record_protected} = directory.remove_cache(controller_id)

      if controller_id != 1 do
        assert {:error, :unsupported_backend_operation} =
                 Grizzly.send_command(1, :default_set, seq_number: 1)
      end

      assert {:ok, :ok} = directory.edit_node(2, %{wake_up_interval: 1234})

      assert {:ok, %{wake_up_interval: 1234} = interview} =
               api.export_node_interview(controller, 2)

      assert :ok = api.apply_node_interview(controller, Map.put(interview, :mode, 3))
      assert Grizzly.listening_mode(2) == {:ok, :frequently_listening}
      assert Grizzly.listening_mode({:virtual, 1}) == {:ok, :always_listening}
      assert {:ok, %{home_id: home_id}} = api.capabilities(controller)
      assert Grizzly.home_id() == Base.encode16(home_id)

      for mode <- [:add, :learn] do
        assert {:ok, %Report{command: %{name: :dsk_report} = dsk_report}} =
                 Grizzly.Node.get_dsk(:gateway, mode, timeout: 5_000)

        assert Command.param!(dsk_report, :add_mode) == mode
        assert %DSK{} = Command.param!(dsk_report, :dsk)
      end

      assert is_list(Grizzly.network_keys())

      assert {:ok, %Report{command: %{name: :default_set_complete}}} =
               Grizzly.Network.reset_controller(notify: false)

      assert File.exists?(Path.join(dir, "resource_directory.db"))
    end
  end
end
