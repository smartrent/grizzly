defmodule Grizzly.ZWave.QRCodeTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.{DSK, QRCode}
  alias Grizzly.ZWave.SmartStart.MetaExtension.UUID16

  defp encode!(info) do
    QRCode.encode!(info) |> IO.iodata_to_binary()
  end

  test "basic Smart Start code" do
    {:ok, dsk} = DSK.parse("51525-35455-41424-34445-31323-33435-21222-32425")
    # This is the ACME Light Dimmer example
    info = %QRCode{
      version: :smart_start,
      dsk: dsk,
      requested_keys: [:s2_authenticated, :s2_unauthenticated],
      zwave_device_type: {:switch_multilevel, :power_switch_multilevel},
      zwave_installer_icon: :specific_light_dimmer_plugin,
      manufacturer_id: 0xFFF0,
      product_type: 0x64,
      product_id: 3,
      application_version: 0x0242
    }

    encoded = encode!(info)
    assert byte_size(encoded) == 90

    assert encoded ==
             "900132782003515253545541424344453132333435212223242500100435301537022065520001000000300578"

    info = %QRCode{info | application_version: {2, 66}}
    assert {:ok, ^info} = QRCode.decode(encoded)
  end

  test "code with UUID" do
    # This is the Oscorp Door Lock w. UUID example
    {:ok, uuid16} = UUID16.new("52E67EA9A1D0868D2B717AB77A5B829B", :hex)
    {:ok, dsk} = DSK.parse("51525 35455 41424 34445 31323 33435 21222 32425")

    info = %QRCode{
      version: :smart_start,
      requested_keys: [:s2_access_control, :s2_authenticated, :s2_unauthenticated],
      dsk: dsk,
      zwave_device_type: {:entry_control, :secure_keypad_door_lock},
      zwave_installer_icon: :generic_door_lock_keypad,
      manufacturer_id: 0xFFF1,
      product_type: 0x3E8,
      product_id: 0x11,
      application_version: {1, 32},
      uuid16: uuid16,
      supported_protocols: []
    }

    encoded = encode!(info)
    assert byte_size(encoded) == 136

    assert encoded ==
             "9001346230075152535455414243444531323334352122232425001016387007680220655210100000017002880642002122232425414243444511121314153132333435"

    assert {:ok, ^info} = QRCode.decode(encoded)
  end

  test "S2-only qr code" do
    {:ok, dsk} = DSK.parse("51525-35455-41424-34445-31323-33435-21222-32425")
    # This is the ACME Light Dimmer (S2-only - not SmartStart) example
    info = %QRCode{
      version: :s2,
      requested_keys: [:s2_authenticated, :s2_unauthenticated],
      dsk: dsk,
      zwave_device_type: {:switch_multilevel, :power_switch_multilevel},
      zwave_installer_icon: :specific_light_dimmer_plugin,
      manufacturer_id: 0xFFF0,
      product_type: 0x64,
      product_id: 3,
      application_version: {2, 66}
    }

    assert encode!(info) ==
             "900032782003515253545541424344453132333435212223242500100435301537022065520001000000300578"

    assert {:ok, ^info} = QRCode.decode(encode!(info))
  end

  defp zwave_decimalize(input) do
    for <<two_bytes::16 <- input>> do
      Integer.to_string(two_bytes, 10) |> String.pad_leading(5, "0")
    end
    |> IO.iodata_to_binary()
  end

  test "creating code for hypothetical hub" do
    {:ok, dsk} = DSK.parse("63239-37621-03012-10660-02008-55918-62746-33260")
    serial = "ABC123456789"
    padded_serial = String.pad_trailing(serial, 16)
    {:ok, uuid16} = UUID16.new("sn:" <> padded_serial, :ascii)

    info = %QRCode{
      version: :smart_start,
      dsk: dsk,
      requested_keys: [:s2_authenticated, :s2_unauthenticated],
      zwave_device_type: {:static_controller, :gateway},
      zwave_installer_icon: :gateway,
      manufacturer_id: 0x0390,
      product_type: 1,
      product_id: 1,
      application_version: 1,
      uuid16: uuid16
    }

    encoded = encode!(info)

    assert byte_size(encoded) == 136

    # Verify that the serial number was properly padded and encoded by
    # re-implementing the algorithm here.
    encoded_serial = zwave_decimalize(padded_serial)
    assert String.ends_with?(encoded, encoded_serial)

    assert encode!(info) ==
             "9001135290036323937621030121066002008559186274633260001000519012800220009120000100001000010642031670617201128511336513879143930822408224"
  end
end
