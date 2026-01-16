defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.EncapsulationFormatInfo do
  @moduledoc """
  Encapsulation format info for a Z/IP Packet
  """

  import Bitwise

  @type security() ::
          :non_secure | :s2_unauthenticated | :s2_authenticated | :s2_access_control | :s0

  @type t() :: %__MODULE__{
          security_classes: [security()],
          crc16: boolean()
        }

  defstruct security_classes: [], crc16: false

  def security_from_byte(0x00), do: :non_secure
  def security_from_byte(0x01), do: :s2_unauthenticated
  def security_from_byte(0x02), do: :s2_authenticated
  def security_from_byte(0x04), do: :s2_access_control
  def security_from_byte(0x80), do: :s0

  def security_to_byte(:non_secure), do: 0x00
  def security_to_byte(:s2_unauthenticated), do: 0x01
  def security_to_byte(:s2_authenticated), do: 0x02
  def security_to_byte(:s2_access_control), do: 0x04
  def security_to_byte(:s0), do: 0x80

  @doc """
  Make a new EncapsulationFormatInfo struct
  """
  @spec new(security(), crc16 :: boolean()) :: t()
  def new(security, crc16) do
    %__MODULE__{security_classes: [security], crc16: crc16}
  end

  @doc """
  Make an `EncapsulationFormatInfo` into a binary
  """
  @spec to_binary(t()) :: binary()
  def to_binary(encap_format) do
    %__MODULE__{security_classes: security_classes, crc16: crc16?} = encap_format

    crc16_byte = if crc16?, do: 0x01, else: 0x00

    security_class_byte =
      Enum.reduce(security_classes, 0, fn security_class, mask ->
        mask ||| security_to_byte(security_class)
      end)

    <<0x84, 0x02, security_class_byte, crc16_byte>>
  end
end
