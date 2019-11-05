defmodule Grizzly.ZipgatewayCfgTest do
  use ExUnit.Case, async: true

  test "default config to string" do
    output = """
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    Eepromfile=/root/zipeeprom.dat
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    """

    cfg = Grizzly.ZipgatewayCfg.new()

    assert output == Grizzly.ZipgatewayCfg.to_string(cfg)
  end

  test "when options are added as string" do
    output = """
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    Eepromfile=/root/zipeeprom.dat
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    ZipProductID = 1
    """

    cfg = Grizzly.ZipgatewayCfg.new(%{product_id: 1})

    assert output == Grizzly.ZipgatewayCfg.to_string(cfg)
  end

  test "write the cfg file to the system" do
    cfg = Grizzly.ZipgatewayCfg.new()

    expected_contents = """
    ZipUnsolicitedDestinationIp6=fd00:aaaa::2
    ZipUnsolicitedDestinationPort=41230
    ZipCaCert=./Portal.ca_x509.pem
    ZipCert=./ZIPR.x509_1024.pem
    ZipPrivKey=./ZIPR.key_1024.pem
    Eepromfile=/root/zipeeprom.dat
    TunScript=./zipgateway.tun
    PVSStorageFile=/root/provisioning_list_store.dat
    ProvisioningConfigFile=/etc/zipgateway_provisioning_list.cfg
    ZipPanIp6=fd00:bbbb::1
    ZipLanIp6=fd00:aaaa::1
    ZipLanGw6=::1
    ZipPSK=123456789012345678901234567890AA
    """

    assert {:ok, cfg_file_path} = Grizzly.ZipgatewayCfg.write(cfg)

    assert expected_contents == File.read!(cfg_file_path)

    :ok = File.rm!(cfg_file_path)
  end
end
