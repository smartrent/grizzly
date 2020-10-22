defmodule Grizzly.Options do
  @moduledoc false

  alias Grizzly.Supervisor
  alias Grizzly.ZIPGateway.Config

  @type t() :: %__MODULE__{
          transport: module(),
          run_zipgateway: boolean(),
          serial_port: String.t(),
          zipgateway_binary: Path.t(),
          zipgateway_config_path: Path.t(),
          on_ready: mfa() | nil,
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
          associations_file: Path.t()
        }

  defstruct run_zipgateway: true,
            serial_port: "/dev/ttyUSB0",
            zipgateway_binary: "/usr/sbin/zipgateway",
            zipgateway_config_path: "/tmp/zipgateway.cfg",
            on_ready: nil,
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
            associations_file: nil

  @spec new([Supervisor.arg()]) :: t()
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @spec to_zipgateway_config(t()) :: Config.t()
  def to_zipgateway_config(grizzly_opts) do
    Config.new(grizzly_opts)
  end
end
