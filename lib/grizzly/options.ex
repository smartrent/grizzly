defmodule Grizzly.Options do
  @moduledoc """
  Grizzly config options.
  """

  alias Grizzly.FirmwareUpdates.OTW.UpdateSpec
  alias Grizzly.Supervisor
  alias Grizzly.Trace

  @typedoc """
  Options for configuring Z-Wave module firmware upgrades.

  * `enabled` - whether firmware upgrades should run automatically after Grizzly
    starts (with a delay of 1 minute). Defaults to `false`.
  * `specs` - a list of firmware upgrade specifications. If multiple specs match,
    the first will be applied. See `Grizzly.FirmwareUpdates.OTW.UpdateSpec`.
  * `module_reset_fun` - a 0-arity function that performs a hard rest of the Z-Wave module.
    Used to detect whether the module is stuck at the bootloader due to a previous
    failed upgrade.
  """
  @type zwave_firmware_options :: %{
          enabled: boolean(),
          specs: [UpdateSpec.t()],
          module_reset_fun: (-> :ok) | nil
        }

  @typedoc """
  See Grizzly.Supervisor
  """
  @type t() :: %__MODULE__{
          backend: :zipgateway | :zwrap,
          zwrap_options: keyword(),
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
          max_associations_per_group: non_neg_integer(),
          database_file: Path.t() | nil,
          indicator_handler: (Grizzly.Indicator.event() -> :ok),
          rf_region: Supervisor.rf_region() | nil,
          power_level: {Supervisor.tx_power(), Supervisor.measured_power()} | nil,
          zwave_firmware: zwave_firmware_options(),
          zw_programmer_path: Path.t(),
          inclusion_adapter: module(),
          extra_config: String.t() | nil,
          trace_options: [Trace.trace_opt()],
          storage_adapter: {module(), term()},
          storage_options: PropertyTable.options()
        }

  # Keep the existing flat configuration fields backwards compatible.
  # credo:disable-for-next-line Credo.Check.Warning.StructFieldAmount
  defstruct backend: :zipgateway,
            zwrap_options: [],
            run_zipgateway: true,
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
            max_associations_per_group: 1,
            database_file: "/data/zipgateway.db",
            indicator_handler: nil,
            rf_region: nil,
            power_level: nil,
            zwave_firmware: %{
              enabled: false,
              zw_programmer_path: "/usr/bin/zw_programmer",
              specs: []
            },
            zw_programmer_path: "/usr/bin/zw_programmer",
            inclusion_adapter: Grizzly.Inclusions.ZWaveAdapter,
            extra_config: nil,
            trace_options: [],
            background_rssi_monitor: [],
            storage_adapter: {Grizzly.Storage.PropertyTable, Grizzly.Storage},
            storage_options: []

  @spec new([Supervisor.arg()]) :: t()
  def new(opts \\ []) do
    Grizzly.Backend.validate!()
    selected = Grizzly.Backend.name()

    if Keyword.has_key?(opts, :backend) and opts[:backend] != selected do
      raise ArgumentError,
            "backend is compiled as #{selected}; rebuild instead of selecting at runtime"
    end

    options = struct(__MODULE__, Keyword.put(opts, :backend, selected))

    unless options.backend in [:zipgateway, :zwrap] do
      raise ArgumentError, "expected :backend to be :zipgateway or :zwrap"
    end

    if options.backend == :zwrap and options.zwave_firmware[:enabled] do
      raise ArgumentError, "automatic controller firmware updates require the ZIPGateway backend"
    end

    options
  end

  if Application.compile_env(:grizzly, :backend, :zipgateway) == :zipgateway do
    alias Grizzly.ZIPGateway.Config

    @spec to_zipgateway_config(t()) :: Config.t()
    def to_zipgateway_config(%__MODULE__{} = opts), do: Config.new(opts)
  else
    def to_zipgateway_config(%__MODULE__{}), do: {:error, :unsupported_backend_operation}
  end
end
