defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.EncapsulationFormatInfo do
  @moduledoc """
  Encapsulation format info for a Z/IP Packet
  """

  import Bitwise

  @type security ::
          :non_secure | :s2_unauthenticated | :s2_authenticated | :s2_access_control | :s0

  def security_to_security_from_byte(0x00), do: :non_secure
  def security_to_security_from_byte(0x01), do: :s2_unauthenticated
  def security_to_security_from_byte(0x02), do: :s2_authenticated
  def security_to_security_from_byte(0x04), do: :s2_access_control
  def security_to_security_from_byte(0x80), do: :s0

  def security_to_security_to_byte(:non_secure), do: 0x00
  def security_to_security_to_byte(:s2_unauthenticated), do: 0x01
  def security_to_security_to_byte(:s2_authenticated), do: 0x02
  def security_to_security_to_byte(:s2_access_control), do: 0x04
  def security_to_security_to_byte(:s0), do: 0x80
  def security_to_security_to_byte(_not_security), do: 0x00

  def to_binary(security_classes) do
    security_class_byte =
      Enum.reduce(security_classes, 0, fn security_class, mask ->
        mask ||| security_to_security_to_byte(security_class)
      end)

    <<0x84, 0x02, security_class_byte, 0x00>>
  end

  def crc16_from_byte(crc16_byte) do
    <<_::size(7), crc16_bit::size(1)>> = <<crc16_byte>>

    if crc16_bit == 1 do
      :crc16
    else
      nil
    end
  end
end
