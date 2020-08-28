defmodule Grizzly.ZWave.CRC.Table do
  @moduledoc false

  use Bitwise

  def ccitt_table(poly) do
    table =
      for i <- 0..255 do
        ccitt_entry(i <<< 8, 0, 0, poly)
      end

    List.to_tuple(table)
  end

  defp ccitt_entry(_, crc, 8, _), do: crc &&& 0xFFFF

  defp ccitt_entry(c, crc, bc, poly) do
    next_crc = if (crc ^^^ c &&& 0x8000) > 0, do: (crc <<< 1) ^^^ poly, else: crc <<< 1
    ccitt_entry(c <<< 1, next_crc, bc + 1, poly)
  end
end
