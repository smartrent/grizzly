defmodule Grizzly.FirmwareUpdates.OTWUpdateRunnerTest do
  use ExUnit.Case, async: false
  use Mimic.DSL

  alias Grizzly.FirmwareUpdates.OTWUpdateRunner
  alias Grizzly.Report
  alias Grizzly.ZWave.Commands.VersionZWaveSoftwareReport

  require Logger

  @default_base_image "test/fixtures/ZW_SAPI_Controller-v7_23_1-EFR32ZG23-full.hex"
  @bootloader_only "test/fixtures/ZW_SAPI_Controller-v7_23_1-EFR32ZG23-bootloader-only.hex"
  @update_full "test/fixtures/ZW_SAPI_Controller-v7_24_2-EFR32ZG23-full.hex"
  @update_image "test/fixtures/ZW_SAPI_Controller-v7_24_2-EFR32ZG23-application-only.gbl"

  @moduletag timeout: :timer.minutes(3)

  setup_all do
    Supervisor.terminate_child(Grizzly.Supervisor, Grizzly.BackgroundRSSIMonitor)
    Supervisor.terminate_child(Grizzly.Supervisor, Grizzly.ZIPGateway.ReadyChecker)
  end

  #
  # TEST REQUIREMENTS
  #
  # * Simplicity Commander (installed via Simplicity Studio)
  # * A Silabs WSTK dev kit with an EFR32ZG23 module connected via USB

  describe "hardware tests" do
    # !! WARNING !!
    # !!   Running these tests will ERASE ALL DATA on the Z-Wave module
    # !!   connected to the configured serial port.
    # !! WARNING !!

    @describetag hardware: true, capture_log: false

    setup :set_mimic_global
    setup :validate_options
    setup :erase_module
    setup :flash_base_image

    test "otw update happy path", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)

      expect Grizzly.send_command(1, :version_zwave_software_get) do
        {:ok, cmd} = VersionZWaveSoftwareReport.new(host_interface_version: "7.23.1")
        {:ok, Report.new(:complete, :command, 1, command: cmd)}
      end

      Process.sleep(100)

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: "fake/shouldn't-get-selected",
              version: "7.24.3",
              applies_to: "~> 7.23.2"
            },
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(5)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(5)

      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(90)
      assert status == :done
      assert reason == :success

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }
    end

    @tag base_image: @update_full
    test "recover from invalid update", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)

      expect Grizzly.send_command(1, :version_zwave_software_get) do
        {:ok, cmd} = VersionZWaveSoftwareReport.new(host_interface_version: "7.23.1")
        {:ok, Report.new(:complete, :command, 1, command: cmd)}
      end

      Process.sleep(100)

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(10)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(10)

      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(10)
      assert status == :error
      assert reason == :update_rejected_by_zwave_module

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }
    end

    test "upload is aborted while in progress", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)

      expect Grizzly.send_command(1, :version_zwave_software_get) do
        {:ok, cmd} = VersionZWaveSoftwareReport.new(host_interface_version: "7.23.1")
        {:ok, Report.new(:complete, :command, 1, command: cmd)}
      end

      Process.sleep(100)

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(5)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(5)

      Process.sleep(10_000)

      expect Grizzly.send_command(1, :version_zwave_software_get), num_calls: 3 do
        {:error, :timeout}
      end

      # Reset the zwave module in the middle of the update
      reset_module(ctx)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateFailedWhileInProgress,
                       state: :set
                     },
                     :timer.seconds(10)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :clear
                     },
                     :timer.seconds(5)

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(20)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(5)

      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(90)
      assert status == :done
      assert reason == :success

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateFailedWhileInProgress,
        state: :clear
      }
    end

    test "upload is aborted while in progress twice", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)

      expect Grizzly.send_command(1, :version_zwave_software_get) do
        {:ok, cmd} = VersionZWaveSoftwareReport.new(host_interface_version: "7.23.1")
        {:ok, Report.new(:complete, :command, 1, command: cmd)}
      end

      Process.sleep(100)

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(5)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(5)

      Process.sleep(5_000)

      stub(Grizzly.send_command(1, :version_zwave_software_get), do: {:error, :timeout})

      # Reset the zwave module in the middle of the update
      reset_module(ctx)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :clear
                     },
                     :timer.seconds(20)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateFailedWhileInProgress,
                       state: :set
                     },
                     :timer.seconds(20)

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(20)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(20)

      Process.sleep(15_000)

      # Reset again
      reset_module(ctx)

      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(10)
      assert status == :error
      assert reason == :update_failed

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }

      refute_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateFailedWhileInProgress,
        state: :clear
      }
    end

    @tag base_image: @bootloader_only
    test "recover from failed update", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)
      stub(Grizzly.send_command(1, :version_zwave_software_get), do: {:error, :timeout})

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(20)

      assert_receive %Alarmist.Event{
                       id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
                       state: :set
                     },
                     :timer.seconds(20)

      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(90)
      assert status == :done
      assert reason == :success

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }
    end

    @tag base_image: nil
    test "see what happens with no bootloader or application", ctx do
      Alarmist.subscribe_all()
      Grizzly.subscribe(:otw_firmware_update)
      stub(Grizzly.start_zipgateway(), do: :ok)
      stub(Grizzly.stop_zipgateway(), do: :ok)
      stub(Grizzly.send_command(1, :version_zwave_software_get), do: {:error, :timeout})

      {:ok, _pid} =
        OTWUpdateRunner.start_link(
          serial_port: ctx[:serial_port],
          module_reset_fun: fn -> reset_module(ctx) end,
          update_specs: [
            %Grizzly.FirmwareUpdates.OTW.UpdateSpec{
              path: @update_image,
              version: "7.24.2",
              applies_to: "~> 7.23"
            }
          ],
          startup_delay: 0
        )

      assert_receive {:grizzly, :otw_firmware_update, :started}, :timer.seconds(20)
      assert_receive {:grizzly, :otw_firmware_update, {status, reason}}, :timer.seconds(90)
      assert status == :error
      assert reason == :bootloader_menu_not_detected

      assert_receive %Alarmist.Event{
        id: Grizzly.FirmwareUpdates.OTWUpdateInProgress,
        state: :clear
      }
    end
  end

  defp flash_base_image(ctx) do
    base_image = Map.get(ctx, :base_image, @default_base_image)

    if base_image != nil do
      commander!(ctx, ["flash", base_image])

      commander!(ctx, [
        "flash",
        "--tokengroup",
        "znet",
        "--tokenfile",
        Path.absname("test/fixtures/sample_encrypt.key"),
        "--tokenfile",
        Path.absname("test/fixtures/sample_tokens.txt")
      ])

      reset_module(ctx)
    end

    :ok
  end

  defp erase_module(ctx) do
    commander!(ctx, ~w(device masserase))
    reset_module(ctx)
    :ok
  end

  defp reset_module(ctx) do
    commander!(ctx, ~w(device reset))
    :ok
  end

  defp validate_options(_ctx) do
    opts = Application.get_all_env(:grizzly)

    if !Version.match?(System.version(), ">= 1.18.0") do
      flunk("Elixir 1.18.0 or greater is required to run the OTW firmware update tests")
    end

    if is_nil(opts) || is_nil(opts[:serial_port]) do
      flunk("""
      To run the OTW firmware update tests, please add the following to config/test.local.exs:

      config :grizzly, serial_port: "/path/to/serial/port"
      """)
    end

    if !File.exists?(opts[:serial_port]) do
      flunk("Serial port not found at: #{opts[:serial_port]}")
    end

    commander = opts[:commander_path] || System.find_executable("commander")

    if is_nil(commander) or !File.exists?(commander) do
      flunk("""
      Simplicity Commander not found. Please ensure that commander is installed via Simplicity Studio
      and either add it to your PATH or add the following to config/test.local.exs:

      config :grizzly, commander_path: "/path/to/commander"
      """)
    end

    Enum.into(opts, %{commander_path: commander})
  end

  defp commander!(ctx, args) do
    args = args ++ ["--identifybyserialport", ctx[:serial_port]]
    {output, status} = System.cmd("commander", args)
    Logger.info("commander #{Enum.join(args, " ")} exited with status #{status}")

    if status != 0 do
      flunk("""
      commander failed with status #{status} and output:
      #{output}
      """)
    end

    {output, status}
  end
end
