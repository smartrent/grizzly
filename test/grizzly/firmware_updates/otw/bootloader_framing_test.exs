defmodule Grizzly.FirmwareUpdates.OTW.BootloaderFramingTest do
  use ExUnit.Case, async: true

  alias Grizzly.FirmwareUpdates.OTW.BootloaderFraming

  test "remove_framing/2 handles single byte control packets" do
    {:ok, frames, rx_buffer} = BootloaderFraming.remove_framing(<<0x06>>, <<>>)
    assert frames == [<<0x06>>]
    assert rx_buffer == <<>>

    {:ok, frames, rx_buffer} = BootloaderFraming.remove_framing(<<0x15>>, <<>>)
    assert frames == [<<0x15>>]
    assert rx_buffer == <<>>

    {:ok, frames, rx_buffer} = BootloaderFraming.remove_framing(<<0x18>>, <<>>)
    assert frames == [<<0x18>>]
    assert rx_buffer == <<>>

    {:ok, frames, rx_buffer} = BootloaderFraming.remove_framing(<<"C">>, <<>>)
    assert frames == [<<"C">>]
    assert rx_buffer == <<>>
  end

  test "remove_framing/2 handles printable data with null bytes" do
    data = "Hello World" <> <<0>> <> "This is a test" <> <<0>> <> "Goodbye"
    {:ok, frames, rx_buffer} = BootloaderFraming.remove_framing(data, <<>>)
    assert frames == ["Hello World", "This is a test", "Goodbye"]
    assert rx_buffer == <<>>
  end

  test "remove_framing/2 handles real data from a z-wave module" do
    data = <<110, 131, 104, 2, 119, 5, 110, 111, 116, 105, 102, 109, 0, 0, 0, 1, 248>>
    assert {:ok, [^data], <<>>} = BootloaderFraming.remove_framing(data, <<>>)

    data =
      <<1, 14, 0, 10, 0, 0, 1, 2, 1, 0, 1, 0, 0, 0, 0, 248, 1, 14, 0, 10, 0, 0, 1, 2, 1, 0, 1, 0,
        0, 0, 0, 248, 1, 14, 0, 10, 0, 0, 1, 2, 1, 0, 1, 0, 0, 0, 0, 248, 1, 14, 0, 10, 0, 0, 1,
        2, 1, 0, 1, 0, 0, 0, 0, 248>>

    assert {:ok, frames, <<>>} = BootloaderFraming.remove_framing(data, <<>>)

    assert 1 == length(frames)

    data =
      <<6, 13, 10, 71, 101, 99, 107, 111, 32, 66, 111, 111, 116, 108, 111, 97, 100, 101, 114, 32,
        118, 50, 46, 48, 50, 46, 48, 49, 13, 10, 49, 46, 32, 117, 112, 108, 111, 97, 100, 32, 103,
        98, 108, 13, 10, 50, 46, 32, 114, 117, 110, 13, 10, 51, 46, 32, 101, 98, 108, 32, 105,
        110, 102, 111, 13, 10, 66, 76, 32, 62, 32, 0, 13, 10>>

    expected_data =
      ~s(\r\nGecko Bootloader v2.02.01\r\n1. upload gbl\r\n2. run\r\n3. ebl info\r\nBL > )

    assert {:ok, frames, <<>>} = BootloaderFraming.remove_framing(data, <<>>)
    assert [<<0x06>>, expected_data, "\r\n"] == frames
  end
end
