defmodule Grizzly.Supervisor do
  @moduledoc """
  Supervisor for running the Grizzly runtime.

  The Grizzly runtime handles command processing, command error isolation,
  management of adding and removing devices, management of firmware updates,
  and managing the underlining `zipgateway` binary.

  If you are just using all the default options you can add the supervisor to
  your application's supervision tree like so:

  ```
  children = [
    Grizzly.Supervisor
  ]
  ```

  The default configuration will look for the Z-Wave controller on the serial
  device `/dev/ttyUSB0`, however if you are using a different serial device
  you can configure this.

  ```
  children = [
    {Grizzly.Supervisor, [serial_port: <serial_port>]}
  ]
  ```

  `Grizzly` will try to run and manage the `zipgateway` binary for you. If
  don't want `Grizzly` to do this you can configure `Grizzly` to not run
  `zipgateway`.

  ```
  children = [
    {Grizzly.Supervisor, [run_zipgateway: false]}
  ]
  ```

  See the type docs for `Grizzly.Supervisor.arg()` to learn more about the
  various configuration options.

  """
  use Supervisor

  require Logger

  alias Grizzly.{Options, ZwaveFirmware}
  alias Grizzly.ZIPGateway.ReadyChecker
  alias Grizzly.ZwaveFirmware

  @typedoc """
  The RF region code you want the Z-Wave controller to operate at.

  * `:eu` - Europe
  * `:us` - US
  * `:anz` - Australia & New Zealand
  * `:hk` - Hong Kong
  * `:id` - India
  * `:il` - Israel
  * `:ru` - Russia
  * `:cn` - China
  * `:us_lr`- US long range
  * `:jp` - Japan
  * `:kr` - Korea
  """
  @type rf_region() ::
          :eu
          | :us
          | :anz
          | :hk
          | :id
          | :il
          | :ru
          | :cn
          | :us_lr
          | :jp
          | :kr

  @typedoc """
  Manifest item for hub Z-Wave firmware updates. Each item identifies a target a chip type, the path
  of the firmware image file, and the firmware version upgrade.
  """
  @type firmware_info() :: %{chip_type: non_neg_integer(), path: String.t(), version: String.t()}

  @typedoc """
  Arguments for running `Grizzly.Supervisor`

  - `:run_zipgateway` - boolean flag to set if Grizzly should be running and
    supervising the `zipgateway` binary. This is useful if you have local
    `zipgateway` running prior to Grizzly running. Default true.
  - `:serial_port` - The serial the Z-Wave controller is is connected to.
     Defaults to `"/dev/ttyUSB0"`
  - `:zipgateway_binary` - the path the zipgateway binary. Defaults to
    `"/usr/sbin/zipgateway`
  - `:zipgateway_config_path` - the path write the zipgateway config file.
     Default to `"/tmp/zipgateway.cfg"`
  - `:transport` - a module that implements the `Grizzly.Transport` behaviour.
    Defaults to `Grizzly.Transports.DTLS`
  - `:zipgateway_port` - the port number of the Z/IP Gateway server. Defaults 41230.
  - `:manufacturer_id` - the manufacturer id given to you by the Z-Wave
    Alliance
  - `:hardware_version` - the hardware version of the hub
  - `:product_id` - the product id of your hub
  - `:product_type` - the type of product the controller is
  - `:serial_log` - path to out but the serial log, useful for advanced
    debugging
  - `:tun_script` - a path to a custom tun script if the default one does not
    work for your system
  - `:port` - port for zipgateway to run its server one. Defaults to `41230`
  - `:lan_ip` - the IP address of the LAN network. That is the network between
    the controlling machine and the Z-Wave network. Defaults to the default
    Z/IP LAN ip.
  - `:pan_ip` - the IP for the Z-Wave private network. That is the devices IP
    addresses. Defaults to the default Z/IP Gateway PAN ip.
  - `:inclusion_handler` - a module that implements the `Grizzly.InclusionHandler`
    behaviour. This is optional.
  - `:firmware_update_handler` - a module that implements the
    `Grizzly.FirmwareUpdateHandler` behaviour. This is optional.
  - `:unsolicited_destination` - configure the ip address and port number for
     the unsolicited destination server.
  - `:unsolicited_data_path` - A path to the directory where the unsolicited
    server should persist data (defaults to `/root`)
  - `:database_file` - `zipgateway` >= 7.14.2 uses an sqlite database to store
    information about the Z-Wave network. This will default to
    "/data/zipgateway.db".
  - `:eeprom_file` - `zipgateway` < 7.14.2 uses an eeprom file to store
    information about the Z-Wave network. This will default to
    "/data/zipeeprom.dat".
  - `:indicator_handler` - A function to run when an `Grizzly.Indicator.event()`
    is received from `zipgateway`. The function should accept an event and
    return `:ok`.
  - `:rf_region` - Specify the RF region to be used by `zipgateway`
  - `:power_level` - A tuple where the first item is the normal TX power level
    and the second item is the measured 0dBm power configuration. See Silabs
    INS14664 (MaxPowerCalc) spreadsheet to figure out the power numbers.
  - `:update_zwave_firmware` - If set to `true`, Grizzly will attempt to update
    the firmware on the Z-Wave module when it starts
  - `:zwave_firmware` - If `:update_zwave_firmware` is `true`, then this is a list
    of firmware files for expected Z-Wave module types.
  - `:zw_programmer_path` - If `:update_zwave_firmware` is `true`, then this is
    the path to the `zw_programmer` application.
  - `:status_reporter` - a module that implements the `Grizzly.StatusReporter`
    behaviour. In no reporter is provided this will use
    `Grizzly.Status.Reporter.Console` by default.

  For the most part the defaults should work out of the box. However, the
  `serial_port` argument is the most likely argument that will need to be
  passed in has it is very much hardware dependent.
  """
  @type arg() ::
          {:run_zipgateway, boolean()}
          | {:serial_port, String.t()}
          | {:zipgateway_binary, String.t()}
          | {:zipgateway_config_path, Path.t()}
          | {:transport, module()}
          | {:zipgateway_port, :inet.port_number()}
          | {:manufacturer_id, non_neg_integer()}
          | {:hardware_version, byte()}
          | {:product_id, byte()}
          | {:product_type, byte()}
          | {:serial_log, Path.t()}
          | {:tun_script, Path.t()}
          | {:lan_ip, :inet.ip_address()}
          | {:pan_ip, :inet.ip_address()}
          | {:inclusion_handler, Grizzly.handler()}
          | {:firmware_update_handler, Grizzly.handler()}
          | {:unsolicited_destination, {:inet.ip_address(), :inet.port_number()}}
          | {:unsolicited_data_path, Path.t()}
          | {:eeprom_file, Path.t()}
          | {:database_file, Path.t()}
          | {:indicator_handler, (Grizzly.Indicator.event() -> :ok)}
          | {:rf_region, rf_region()}
          | {:power_level, {tx_power(), measured_power()}}
          | {:status_reporter, module()}
          | {:update_zwave_firmware, boolean()}
          | {:zwave_firmware, [firmware_info()]}
          | {:zw_programmer_path, Path.t()}

  @typedoc """
  The power level used when transmitting frames at normal power

  See Silabs INS14664 (MaxPowerCalc) spreadsheet to figure out tx power levels.
  """
  @type tx_power() :: non_neg_integer()

  @typedoc """
  The output power measured from the antenna when the `tx_power()` is set to 0dBm
  """
  @type measured_power() :: integer()

  @doc """
  Start the Grizzly.Supervisor
  """
  @spec start_link([arg()]) :: Supervisor.on_start()
  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl Supervisor
  def init(init_args) do
    options = Options.new(init_args)
    ZwaveFirmware.maybe_run_zwave_firmware_update(options)

    Supervisor.init(children(options), strategy: :one_for_one)
  end

  defp children(options) do
    [
      # According to Z-Wave specification we need to have a global
      # sequence number counter that starts at a random number between
      # 0 and 0xFF (255)
      {Grizzly.SeqNumber, Enum.random(0..255)},
      Grizzly.Trace,
      {Registry, [keys: :duplicate, name: Grizzly.Events.Registry]},
      {Registry, [keys: :unique, name: Grizzly.ConnectionRegistry]},
      {Grizzly.Associations, options},

      # TODO: move unsolicited server stuff to own supervisor
      Grizzly.UnsolicitedServer.Messages,
      Grizzly.UnsolicitedServer.SocketSupervisor,
      {Grizzly.UnsolicitedServer, options},
      ##########################

      # Supervisor for starting connections to Z-Wave nodes
      {Grizzly.Connections.Supervisor, options},

      # Supervisor for starting and stopping Z-Wave inclusions
      {Grizzly.Inclusions.InclusionRunnerSupervisor, options},

      # Supervisor for updating firmware
      {Grizzly.FirmwareUpdates.FirmwareUpdateRunnerSupervisor, options},

      # Supervisor for running commands
      Grizzly.Commands.CommandRunnerSupervisor,

      # Supervisor for virtual devices
      {Grizzly.VirtualDevicesSupervisor, options},
      {ReadyChecker, [status_reporter: options.status_reporter]}
    ]
    |> maybe_run_zipgateway_supervisor(options)
  end

  defp maybe_run_zipgateway_supervisor(children, options) do
    if options.run_zipgateway do
      # Supervisor for the zipgateway binary
      [{Grizzly.ZIPGateway.Supervisor, options} | children]
    else
      children
    end
  end
end
