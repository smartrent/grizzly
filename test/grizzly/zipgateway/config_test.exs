defmodule Grizzly.ZIPGateway.ConfigTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZIPGateway.Config

  def cfg_path(), do: Path.join(System.tmp_dir!(), "/zipgateay.cfg")

  test "default config to string" do
    output = """
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    ExtraClasses= 133 89 90 142 108 143
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    """

    cfg = Config.new()

    assert output == Config.to_string(cfg)
  end

  test "with eeprom_file" do
    output = """
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    ExtraClasses= 133 89 90 142 108 143
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    Eepromfile=/data/zipeeprom.dat
    """

    cfg = Config.new(%{eeprom_file: "/data/zipeeprom.dat"})

    assert output == Config.to_string(cfg)
  end

  test "when options are added as string" do
    output = """
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    ZipProductID=1
    ExtraClasses= 133 89 90 142 108 143
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    ZipGwDatabase=/tmp/zipgateway.db
    """

    cfg = Config.new(%{product_id: 1, database_file: "/tmp/zipgateway.db"})

    assert output == Config.to_string(cfg)
  end

  test "write the cfg file to the system" do
    cfg = Config.new()

    expected_contents = """
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    ExtraClasses= 133 89 90 142 108 143
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    """

    assert :ok = Config.write(cfg, cfg_path())

    assert expected_contents == File.read!(cfg_path())

    :ok = File.rm!(cfg_path())
  end
end
