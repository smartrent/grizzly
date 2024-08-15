defmodule Grizzly.ZIPGateway.Config do
  @moduledoc """
  Builds valid `zipgateway.cfg` based on Grizzly options.
  """

  # This module is for making the `zipgateway.cfg` file

  require Logger

  alias Grizzly.Supervisor

  @type t :: %__MODULE__{
          ca_cert: Path.t(),
          cert: Path.t(),
          priv_key: Path.t(),
          tun_script: Path.t(),
          pvs_storage_file: Path.t(),
          provisioning_config_file: Path.t(),
          pan_ip: :inet.ip_address(),
          lan_ip: :inet.ip_address(),
          lan_gw6: String.t(),
          psk: String.t(),
          manufacturer_id: non_neg_integer() | nil,
          hardware_version: non_neg_integer() | nil,
          product_id: non_neg_integer() | nil,
          product_type: non_neg_integer() | nil,
          serial_log: String.t() | nil,
          extra_classes: [byte()],
          unsolicited_destination: {:inet.ip_address(), :inet.port_number()},
          database_file: Path.t() | nil,
          rf_region: Supervisor.rf_region() | nil,
          power_level: {Supervisor.tx_power(), Supervisor.measured_power()} | nil,
          extra_config: String.t() | nil
        }

  defstruct ca_cert: "./Portal.ca_x509.pem",
            cert: "./ZIPR.x509_1024.pem",
            priv_key: "./ZIPR.key_1024.pem",
            tun_script: "./zipgateway.tun",
            pvs_storage_file: "/root/provisioning_list_store.dat",
            provisioning_config_file: "/data/zipgateway_provisioning_list.cfg",
            pan_ip: {0xFD00, 0xBBBB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01},
            lan_ip: {0xFD00, 0xAAAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01},
            lan_gw6: "::1",
            psk: "123456789012345678901234567890AA",
            serial_log: nil,
            product_id: nil,
            product_type: nil,
            hardware_version: nil,
            manufacturer_id: nil,
            extra_classes: [0x85, 0x59, 0x5A, 0x8E, 0x6C, 0x8F],
            unsolicited_destination: {{0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}, 41230},
            database_file: nil,
            identify_script: nil,
            rf_region: nil,
            power_level: nil,
            extra_config: nil

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
        :tun_script,
        :lan_ip,
        :pan_ip,
        :database_file,
        :rf_region,
        :power_level,
        :extra_config
      ])

    struct(__MODULE__, opts)
  end

  @doc """
  Write the contents of the `ZipgatewayCfg.t()` to the file system
  """
  @spec write(t(), Path.t()) :: :ok | {:error, File.posix()}
  def write(cfg, path) do
    contents = __MODULE__.to_string(cfg)
    File.write(path, contents)
  end

  @doc """
  Turn the `ZipgatewayCfg.t()` into a string
  """
  @spec to_string(t()) :: String.t()
  def to_string(cfg) do
    """
    ZipCaCert=#{cfg.ca_cert}
    ZipCert=#{cfg.cert}
    ZipPrivKey=#{cfg.priv_key}
    TunScript=#{cfg.tun_script}
    PVSStorageFile=#{cfg.pvs_storage_file}
    ProvisioningConfigFile=#{cfg.provisioning_config_file}
    ZipLanGw6=#{cfg.lan_gw6}
    ZipPSK=#{cfg.psk}
    """
    |> maybe_put_config_item(cfg, :serial_log, "SerialLog")
    |> maybe_put_config_item(cfg, :product_id, "ZipProductID")
    |> maybe_put_config_item(cfg, :manufacturer_id, "ZipManufacturerID")
    |> maybe_put_config_item(cfg, :hardware_version, "ZipHardwareVersion")
    |> maybe_put_config_item(cfg, :product_type, "ZipProductType")
    |> maybe_put_config_item(cfg, :extra_classes, "ExtraClasses")
    |> maybe_put_config_item(cfg, :pan_ip, "ZipPanIp6")
    |> maybe_put_config_item(cfg, :lan_ip, "ZipLanIp6")
    |> maybe_put_config_item(cfg, :unsolicited_destination, nil)
    |> maybe_put_config_item(cfg, :database_file, "ZipGwDatabase")
    |> maybe_put_config_item(cfg, :identify_script, "ZipNodeIdentifyScript")
    |> maybe_put_config_item(cfg, :rf_region, "ZWRFRegion")
    |> maybe_put_config_item(cfg, :power_level, "")
    |> maybe_put_extra_config(cfg)
  end

  @doc """
  Ensure required files are on disk and contain the correct contents

  This is useful to ensure other tools provided by `zipgateway` can work.
  """
  @spec ensure_files(t()) :: t()
  def ensure_files(%__MODULE__{} = config) do
    :ok = ensure_provisioning_list_config(config.provisioning_config_file)

    config
  end

  defp ensure_provisioning_list_config(provisioning_list_config_path) do
    if File.exists?(provisioning_list_config_path) do
      :ok
    else
      contents = """
      # Provisioning list for Z/IP Gateway Smart Start devices.
      ZIPGateway Smart Start Provisioning List Configuration, version = 1.0.
      """

      case File.write(provisioning_list_config_path, contents) do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.warning("Failed to write provision list file: #{inspect(reason)}")
          :ok
      end
    end
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

  defp maybe_put_config_item(config_string, cfg, :unsolicited_destination, _) do
    {ip, port} = cfg.unsolicited_destination

    ip_string =
      ip
      |> :inet.ntoa()
      |> Kernel.to_string()

    config_string <>
      "ZipUnsolicitedDestinationIp6=#{ip_string}\n" <>
      "ZipUnsolicitedDestinationPort=#{port}\n"
  end

  defp maybe_put_config_item(config_string, cfg, :identify_script = field, cfg_name) do
    case Map.get(cfg, field) do
      nil ->
        script_path = Application.app_dir(:grizzly, ["priv", "indicator.sh"])
        config_string <> "#{cfg_name}=#{script_path}\n"

      script_path ->
        config_string <> "#{cfg_name}=#{script_path}\n"
    end
  end

  defp maybe_put_config_item(config_string, cfg, :power_level = field, _cfg_name) do
    case Map.get(cfg, field) do
      nil ->
        config_string

      {tx_powerlevel, measured_dbm} ->
        config_string <>
          "NormalTxPowerLevel=#{tx_powerlevel}\nMeasured0dBmPower=#{measured_dbm}\n"
    end
  end

  defp maybe_put_config_item(config_string, cfg, field, cfg_name)
       when field in [:pan_ip, :lan_ip] do
    ip =
      cfg
      |> Map.get(field)
      |> :inet.ntoa()
      |> List.to_string()

    config_string <> "#{cfg_name}=#{ip}\n"
  end

  defp maybe_put_config_item(config_string, cfg, :rf_region, cfg_name) do
    case Map.get(cfg, :rf_region) do
      nil ->
        config_string

      region ->
        config_string <> "#{cfg_name}=#{rf_region(region)}\n"
    end
  end

  defp maybe_put_config_item(config_string, cfg, field, cfg_name) do
    cfg_item = Map.get(cfg, field)

    if cfg_item != nil do
      config_string <> "#{cfg_name}=#{cfg_item}\n"
    else
      config_string
    end
  end

  defp maybe_put_extra_config(config_string, cfg) do
    if cfg.extra_config != nil do
      config_string <> cfg.extra_config
    else
      config_string
    end
  end

  defp rf_region(:eu), do: 0x00
  defp rf_region(:us), do: 0x01
  defp rf_region(:anz), do: 0x02
  defp rf_region(:hk), do: 0x03
  defp rf_region(:id), do: 0x05
  defp rf_region(:il), do: 0x06
  defp rf_region(:ru), do: 0x07
  defp rf_region(:cn), do: 0x08
  defp rf_region(:us_lr), do: 0x09
  defp rf_region(:jp), do: 0x20
  defp rf_region(:kr), do: 0x21
end
