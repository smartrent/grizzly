defmodule Grizzly.Packet.HeaderExtension.EncapsulationFormatInfo do
  defstruct security_to_security: :non_secure, crc16?: false

  def new(security_to_security, crc16?) do
    %__MODULE__{security_to_security: security_to_security, crc16?: crc16?}
  end

  def security_to_security_from_byte(0x00), do: :non_secure
  def security_to_security_from_byte(0x01), do: :s2_unauthenticated
  def security_to_security_from_byte(0x02), do: :s2_authenticated
  def security_to_security_from_byte(0x04), do: :s2_access_control
  def security_to_security_from_byte(0x80), do: :s0

  def crc16_from_byte(crc16_byte) do
    <<_::size(7), crc16_bit::size(1)>> = <<crc16_byte>>
    crc16_bit == 1
  end
end
