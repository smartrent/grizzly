defmodule Grizzly.CommandClass.ManufacturerSpecific.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.ManufacturerSpecific

  test "encoding bytes correctly" do
    assert {:ok, 0x00} ==
             ManufacturerSpecific.encode_device_id_type(:oem_factory_default_device_id_type)

    assert {:ok, 0x01} == ManufacturerSpecific.encode_device_id_type(:serial_number)
    assert {:ok, 0x02} == ManufacturerSpecific.encode_device_id_type(:pseudo_random)
  end

  test "decode bytes correctly" do
    assert {:error, :invalid_arg, :fizzbuzz} ==
             ManufacturerSpecific.encode_device_id_type(:fizzbuzz)
  end
end
