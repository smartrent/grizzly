defmodule Grizzly.ZWave.CommandClasses.CRC16Encap do
  @moduledoc """
  "Crc16Encap" Command Class

  The CRC-16 Encapsulation Command Class is used to encapsulate a command with an additional CRC-16
  checksum to ensure integrity of the payload.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x56

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :crc_16_encap
end
