defmodule Grizzly.ZIPGateway.Config do
  @moduledoc false

  # This module is for making the `zipgateway.cfg` file

  alias Grizzly.ZIPGateway

  @type t :: %__MODULE__{
          unsolicited_destination_ip6: String.t(),
          unsolicited_destination_port: :inet.port_number(),
          ca_cert: Path.t(),
          cert: Path.t(),
          priv_key: Path.t(),
          eeprom_file: Path.t(),
          tun_script: Path.t(),
          pvs_storage_file: Path.t(),
          provisioning_config_file: Path.t(),
          pan_ip6: String.t(),
          lan_ip6: String.t(),
          lan_gw6: String.t(),
          psk: String.t(),
          manufacturer_id: non_neg_integer() | nil,
          hardware_version: non_neg_integer() | nil,
          product_id: non_neg_integer() | nil,
          product_type: non_neg_integer() | nil,
          serial_log: String.t() | nil,
          extra_classes: [byte()]
        }

  defstruct unsolicited_destination_ip6: "fd00:aaaa::2",
            unsolicited_destination_port: 41230,
            ca_cert: "./Portal.ca_x509.pem",
            cert: "./ZIPR.x509_1024.pem",
            priv_key: "./ZIPR.key_1024.pem",
            eeprom_file: "/root/zipeeprom.dat",
            tun_script: "./zipgateway.tun",
            pvs_storage_file: "/root/provisioning_list_store.dat",
            provisioning_config_file: "/etc/zipgateway_provisioning_list.cfg",
            pan_ip6: "fd00:bbbb::1",
            lan_ip6: "fd00:aaaa::1",
            lan_gw6: "::1",
            psk: "123456789012345678901234567890AA",
            serial_log: nil,
            product_id: nil,
            product_type: nil,
            hardware_version: nil,
            manufacturer_id: nil,
            extra_classes: [0x85, 0x59, 0x5A, 0x8E, 0x6C, 0x8F]

  @doc """
  Make a new `ZipgatewayCfg.t()` from the supplied options
  """
  @spec new(map()) :: t()
  def new(opts \\ %{}) do
    opts =
      Map.take(opts, [
        :manufacturer_id,
        :hardware_version,
        :product_id,
        :product_type,
        :serial_log,
        :tun_script
      ])

    struct(__MODULE__, opts)
  end

  @doc """
  Write the contents of the `ZipgatewayCfg.t()` to the file system
  """
  @spec write(t()) :: :ok | {:error, File.posix()}
  def write(cfg) do
    contents = __MODULE__.to_string(cfg)
    File.write(ZIPGateway.cfg_path(), contents)
  end

  @doc """
  Turn the `ZipgatewayCfg.t()` into a string
  """
  @spec to_string(t()) :: String.t()
  def to_string(cfg) do
    """
    ZipUnsolicitedDestinationIp6=#{cfg.unsolicited_destination_ip6}
    ZipUnsolicitedDestinationPort=#{cfg.unsolicited_destination_port}
    ZipCaCert=#{cfg.ca_cert}
    ZipCert=#{cfg.cert}
    ZipPrivKey=#{cfg.priv_key}
    Eepromfile=#{cfg.eeprom_file}
    TunScript=#{cfg.tun_script}
    PVSStorageFile=#{cfg.pvs_storage_file}
    ProvisioningConfigFile=#{cfg.provisioning_config_file}
    ZipPanIp6=#{cfg.pan_ip6}
    ZipLanIp6=#{cfg.lan_ip6}
    ZipLanGw6=#{cfg.lan_gw6}
    ZipPSK=#{cfg.psk}
    """
    |> maybe_put_config_item(cfg, :serial_log, "SerialLog")
    |> maybe_put_config_item(cfg, :product_id, "ZipProductID")
    |> maybe_put_config_item(cfg, :manufacturer_id, "ZipManufacturerID")
    |> maybe_put_config_item(cfg, :hardware_version, "ZipHardwareVersion")
    |> maybe_put_config_item(cfg, :product_type, "ZipProductType")
    |> maybe_put_config_item(cfg, :extra_classes, "ExtraClasses")
  end

  defp maybe_put_config_item(config_string, cfg, :extra_classes = field, cfg_name) do
    case Map.get(cfg, field) do
      nil ->
        config_string

      extra_command_classes ->
        extra_command_classes_string = Enum.join(extra_command_classes, " ")
        config_string <> "#{cfg_name}= #{extra_command_classes_string}\n"
    end
  end

  defp maybe_put_config_item(config_string, cfg, field, cfg_name) do
    cfg_item = Map.get(cfg, field)

    if cfg_item != nil do
      config_string <> "#{cfg_name} = #{cfg_item}\n"
    else
      config_string
    end
  end
end
