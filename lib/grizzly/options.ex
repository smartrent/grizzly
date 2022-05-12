defmodule Grizzly.Options do
  @moduledoc false

  alias Grizzly.Supervisor
  alias Grizzly.ZIPGateway.Config

  require Logger

  @typedoc """
  See Grizzly.Supervisor
  """
  @type t() :: %__MODULE__{
          transport: module(),
          run_zipgateway: boolean(),
          serial_port: String.t(),
          zipgateway_binary: Path.t(),
          zipgateway_config_path: Path.t(),
          zipgateway_port: :inet.port_number(),
          manufacturer_id: non_neg_integer() | nil,
          hardware_version: byte() | nil,
          product_id: byte() | nil,
          product_type: byte() | nil,
          serial_log: Path.t() | nil,
          tun_script: Path.t(),
          lan_ip: :inet.ip_address(),
          pan_ip: :inet.ip_address(),
          inclusion_handler: Grizzly.handler() | nil,
          firmware_update_handler: Grizzly.handler() | nil,
          unsolicited_destination: {:inet.ip_address(), :inet.port_number()},
          associations_file: Path.t(),
          eeprom_file: Path.t() | nil,
          database_file: Path.t() | nil,
          indicator_handler: (Grizzly.Indicator.event() -> :ok),
          rf_region: Supervisor.rf_region() | nil,
          power_level: {Supervisor.tx_power(), Supervisor.measured_power()} | nil,
          status_reporter: module(),
          update_zwave_firmware: boolean(),
          zwave_firmware: [Supervisor.firmware_info()],
          zw_programmer_path: Path.t()
        }

  defstruct run_zipgateway: true,
            serial_port: "/dev/ttyUSB0",
            zipgateway_binary: "/usr/sbin/zipgateway",
            zipgateway_config_path: "/tmp/zipgateway.cfg",
            transport: Grizzly.Transports.DTLS,
            zipgateway_port: 41230,
            manufacturer_id: nil,
            hardware_version: nil,
            product_id: nil,
            product_type: nil,
            serial_log: nil,
            tun_script: "./zipgateway.tun",
            pan_ip: {0xFD00, 0xBBBB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01},
            lan_ip: {0xFD00, 0xAAAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01},
            inclusion_handler: nil,
            firmware_update_handler: nil,
            unsolicited_destination: {{0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}, 41230},
            associations_file: nil,
            eeprom_file: "/data/zipeeprom.dat",
            database_file: "/data/zipgateway.db",
            indicator_handler: nil,
            rf_region: nil,
            power_level: nil,
            status_reporter: Grizzly.StatusReporter.Console,
            update_zwave_firmware: false,
            zwave_firmware: [],
            zw_programmer_path: "/usr/bin/zw_programmer"

  @spec new([Supervisor.arg()]) :: t()
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @spec to_zipgateway_config(t(), boolean()) :: Config.t()
  def to_zipgateway_config(%__MODULE__{database_file: file} = grizzly_opts, use_database?)
      when file == nil or not use_database? do
    # Build a zipgateway configuration for zipgateway <7.14.2
    Config.new(grizzly_opts)
  end

  def to_zipgateway_config(%__MODULE__{} = grizzly_opts, true = _use_database?) do
    # Build a zipgateway configuration for zipgateway >= 7.14.2. This version
    # of zipgateway will exit if an eeprom file is specified
    Config.new(%{grizzly_opts | eeprom_file: nil})
  end
end
