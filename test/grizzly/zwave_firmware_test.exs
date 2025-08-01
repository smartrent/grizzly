defmodule Grizzly.ZWaveFirmwareTest do
  use ExUnit.Case, async: false
  use Mimic

  setup :set_mimic_global

  alias Grizzly.{Options, ZWaveFirmware, ZWaveFirmware.UpgradeSpec}

  @corrupt_fw_output """
  Using serial device /dev/tty.usbmodem0004402548831
  SerialAPI: Retransmission 0 of 0x07
  SerialAPI: Retransmission 1 of 0x07
  SerialAPI: Retransmission 2 of 0x07
  SerialAPI: Retransmission 3 of 0x07
  SerialAPI: Retransmission 4 of 0x07
  SerialAPI: Retransmission 5 of 0x07
  SerialAPI: Retransmission 6 of 0x07
  SerialAPI: Retransmission 7 of 0x07
  SerialAPI: Reopening serial port
  """

  describe "maybe_run_zwave_firmware_update/1" do
    test "normal operation" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {zw_programmer_version_output("7.18.02"), 0}
      end)
      |> expect(:cmd, fn "/usr/bin/zw_programmer",
                         ["-s", "/dev/null", "-p", "/path/to/7.19.3.gbl"] ->
        {"", 0}
      end)

      MockZWaveResetter
      |> expect(:reset_zwave_module, fn -> :ok end)

      pid = self()

      MockStatusReporter
      |> expect(:zwave_firmware_update_status, 2, fn status ->
        send(pid, status)
      end)

      ZWaveFirmware.maybe_run_zwave_firmware_update(get_options())

      assert_receive :started
      assert_receive {:done, :success}
    end

    test "failed update" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {zw_programmer_version_output("7.18.02"), 0}
      end)
      |> expect(:cmd, fn "/usr/bin/zw_programmer",
                         ["-s", "/dev/null", "-p", "/path/to/7.19.3.gbl"] ->
        {"", 1}
      end)

      # When an update fails, the module will be reset twice: once at the beginning
      # and once after the failure to try to back to a clean state.
      MockZWaveResetter
      |> expect(:reset_zwave_module, 2, fn -> :ok end)

      pid = self()

      MockStatusReporter
      |> expect(:zwave_firmware_update_status, 2, fn status ->
        send(pid, status)
      end)

      ZWaveFirmware.maybe_run_zwave_firmware_update(get_options())

      assert_receive :started
      assert_receive {:error, _}
    end

    test "stuck at bootloader (500-series)" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {@corrupt_fw_output, 0}
      end)
      |> expect(:cmd, fn "/usr/bin/zw_programmer",
                         ["-s", "/dev/null", "-p", "/path/to/7.20.1.gbl", "-a"] ->
        {"", 0}
      end)

      MockZWaveResetter
      |> expect(:reset_zwave_module, fn -> :ok end)

      pid = self()

      MockStatusReporter
      |> expect(:zwave_firmware_update_status, 2, fn status ->
        send(pid, status)
      end)

      ZWaveFirmware.maybe_run_zwave_firmware_update(get_options(%{chip_series: 500}))

      assert_receive :started
      assert_receive {:done, :success}
    end

    test "stuck at bootloader (700/800-series)" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {@corrupt_fw_output, 0}
      end)
      |> expect(:cmd, fn "/usr/bin/zw_programmer",
                         ["-s", "/dev/null", "-p", "/path/to/7.20.1.gbl", "-a", "-7"] ->
        {"", 0}
      end)

      MockZWaveResetter
      |> expect(:reset_zwave_module, fn -> :ok end)

      pid = self()

      MockStatusReporter
      |> expect(:zwave_firmware_update_status, 2, fn status ->
        send(pid, status)
      end)

      ZWaveFirmware.maybe_run_zwave_firmware_update(get_options())

      assert_receive :started
      assert_receive {:done, :success}
    end
  end

  describe "find_upgrade_spec/2" do
    test "with current version" do
      specs = [
        %UpgradeSpec{version: "7.18.2", path: "", applies_to: "~> 7.18.0"},
        %UpgradeSpec{version: "7.18.3", path: "", applies_to: "~> 7.18.0"},
        %UpgradeSpec{version: "7.20.0", path: "", applies_to: "~> 7.19.3"},
        %UpgradeSpec{version: "7.19.4", path: "", applies_to: "~> 7.19.0"},
        %UpgradeSpec{version: "7.18.0", path: "", applies_to: ">= 0.0.0"}
      ]

      assert %{version: "7.18.0"} = ZWaveFirmware.find_upgrade_spec(specs, "7.15.0")
      assert %{version: "7.18.3"} = ZWaveFirmware.find_upgrade_spec(specs, "7.18.0")
      assert %{version: "7.18.3"} = ZWaveFirmware.find_upgrade_spec(specs, "7.18.2")
      refute ZWaveFirmware.find_upgrade_spec(specs, "7.18.3")
      refute ZWaveFirmware.find_upgrade_spec(specs, "7.18.4")
      assert %{version: "7.19.4"} = ZWaveFirmware.find_upgrade_spec(specs, "7.19.0")
      assert %{version: "7.20.0"} = ZWaveFirmware.find_upgrade_spec(specs, "7.19.3")
    end

    test "without current version" do
      specs = [
        %UpgradeSpec{version: "7.19.4", path: "", applies_to: "~> 7.19.0"},
        %UpgradeSpec{version: "7.20.1", path: "", applies_to: "~> 7.20.0"}
      ]

      spec = ZWaveFirmware.find_upgrade_spec(specs, nil)
      assert spec.version == "7.20.1"
    end
  end

  describe "zwave_module_version/1" do
    test "parses output correctly" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {zw_programmer_version_output("7.16.03"), 0}
      end)
      |> expect(:cmd, fn "/usr/bin/zw_programmer", ["-s", "/dev/null", "-t"] ->
        {@corrupt_fw_output, 1}
      end)

      opts = %Options{
        serial_port: "/dev/null",
        zw_programmer_path: "/usr/bin/zw_programmer",
        zwave_firmware: %{
          enabled: true,
          specs: []
        }
      }

      version = ZWaveFirmware.zwave_module_version(opts)
      assert %Version{major: 7, minor: 16, patch: 3} = version

      version = ZWaveFirmware.zwave_module_version(opts)
      refute version
    end

    test "raises if serial init fails" do
      MuonTrap
      |> expect(:cmd, fn "/usr/bin/zw_programmer", _args ->
        {"Serial Init failed", 0}
      end)

      assert_raise Grizzly.FirmwareError, fn ->
        ZWaveFirmware.zwave_module_version(get_options())
      end
    end
  end

  defp zw_programmer_version_output(version) do
    """
    Using serial device /dev/ttyZwave
    Connected to Serial device: OK
    Serial version: 9, Chip type: 8, Chip version: 0, SDK: #{version}, SDK Build no: 238 SDK git hash: 30303030303030303030303030303030
    ----------------------------------------------------------------------------
    Note that for bridge7.16 and onward NVM migration is handled by the Z-Wave
    module automatically so zw_nvm_converter must not be used.
    ----------------------------------------------------------------------------
    Chip library: 7, ZW protocol: 7.16, NVM: bridge7.16
    nvm_id: bridge7.16
    Closing Serial connection
    """
  end

  defp get_options(overrides \\ %{}) do
    %Options{
      serial_port: "/dev/null",
      status_reporter: MockStatusReporter,
      zw_programmer_path: "/usr/bin/zw_programmer",
      zwave_firmware:
        Map.merge(
          %{
            enabled: true,
            chip_series: 700,
            module_reset_fun: &MockZWaveResetter.reset_zwave_module/0,
            specs: [
              %UpgradeSpec{
                version: "7.19.3",
                path: "/path/to/7.19.3.gbl",
                applies_to: ">= 0.0.0"
              },
              %UpgradeSpec{
                version: "7.20.1",
                path: "/path/to/7.20.1.gbl",
                applies_to: "~> 7.19.0"
              }
            ]
          },
          overrides
        )
    }
  end
end
