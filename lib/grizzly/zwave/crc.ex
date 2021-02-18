defmodule Grizzly.ZWave.CRC do
  @moduledoc """
  CRC for Z-Wave commands

  Some commands will need to use CRC for checking checksums. This module
  exposes CRC functions to be able to run those checks.
  """

  @crc16_aug_ccitt :cerlc.init(:crc16_aug_ccitt)
  @type uint16() :: 0..65535

  @doc """
  CRC-16/AUG-CCITT
  """
  @spec crc16_aug_ccitt(binary() | [byte()]) :: uint16()
  def crc16_aug_ccitt(data) do
    :cerlc.calc_crc(data, @crc16_aug_ccitt)
  end
end
