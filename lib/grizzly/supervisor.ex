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

  alias Grizzly.Options
  alias Grizzly.ZIPGateway.ReadyChecker

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
  - `:on_ready` - Module, function, args to run after Grizzly can establish
    that zipgateway is up and running. If not passed nothing will be called.
    Defaults to `nil`.
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
  - `:power_level - A tuple where the first item is the normal TX power level
    and the second item is the measured 0dBm power configuration

  For the most part the defaults should work out of the box. However, the
  `serial_port` argument is the most likely argument that will need to be
  passed in has it is very much hardware dependent.
  """
  @type arg() ::
          {:run_zipgateway, boolean()}
          | {:serial_port, String.t()}
          | {:zipgateway_binary, String.t()}
          | {:zipgateway_config_path, Path.t()}
          | {:on_ready, mfa()}
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

  @doc """
  Start the Grizzly.Supervisor
  """
  @spec start_link([arg()]) :: Supervisor.on_start()
  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl Supervisor
  def init(init_args) do
    Supervisor.init(children(init_args), strategy: :one_for_one)
  end

  defp children(init_args) do
    options = Options.new(init_args)

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
      Grizzly.Commands.CommandRunnerSupervisor
    ]
    |> maybe_run_zipgateway_supervisor(options)
    |> maybe_start_on_ready_checker(options)
  end

  defp maybe_run_zipgateway_supervisor(children, options) do
    if options.run_zipgateway do
      # Supervisor for the zipgateway binary
      [{Grizzly.ZIPGateway.Supervisor, options} | children]
    else
      children
    end
  end

  defp maybe_start_on_ready_checker(children, opts) do
    if opts.on_ready do
      children ++ [{ReadyChecker, opts.on_ready}]
    else
      children
    end
  end
end
