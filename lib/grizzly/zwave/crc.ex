defmodule Grizzly.ZWave.CRC do
  @moduledoc """
  CRC for Z-Wave commands

  Some commands will need to use CRC for checking checksums. This module
  exposes CRC functions to be able to run those checks.
  """

  use Bitwise

  @table Grizzly.ZWave.CRC.Table.ccitt_table(0x1021)

  @type uint16() :: 0..65535

  @doc """
  CRC-16/AUG-CCITT
  """
  @spec crc16_aug_ccitt(binary() | [byte()]) :: uint16()
  def crc16_aug_ccitt(data) when is_binary(data) do
    data
    |> :binary.bin_to_list()
    |> crc16_aug_ccitt()
  end

  def crc16_aug_ccitt(data) when is_list(data) do
    crc_ccitt(data, 0x1D0F)
  end

  defp crc_ccitt([x | rem], crc) do
    index = (crc >>> 8) ^^^ x
    crc = (crc <<< 8) ^^^ elem(@table, index) &&& 0xFFFF
    crc_ccitt(rem, crc)
  end

  defp crc_ccitt([], crc), do: crc
end
