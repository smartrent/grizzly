defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.EncapsulationFormatInfo do
  @type security ::
          :non_secure | :s2_unauthenticated | :s2_authenticated | :s2_access_control | :s0

  def security_to_security_from_byte(0x00), do: :non_secure
  def security_to_security_from_byte(0x01), do: :s2_unauthenticated
  def security_to_security_from_byte(0x02), do: :s2_authenticated
  def security_to_security_from_byte(0x04), do: :s2_access_control
  def security_to_security_from_byte(0x80), do: :s0

  def crc16_from_byte(crc16_byte) do
    <<_::size(7), crc16_bit::size(1)>> = <<crc16_byte>>

    if crc16_bit == 1 do
      :crc16
    else
      nil
    end
  end
end
