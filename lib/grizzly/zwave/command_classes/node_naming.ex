defmodule Grizzly.ZWave.CommandClasses.NodeNaming do
  @moduledoc """
  "NodeNaming" Command Class

  The Node Naming (and Location) Command Class is used to assign a name and a location text string to a
  supporting node.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x77

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :node_naming

  def encoding_to_byte(:ascii), do: 0x00
  def encoding_to_byte(:extended_ascii), do: 0x01
  def encoding_to_byte(:utf_16), do: 0x02

  def encoding_from_byte(0x00), do: {:ok, :ascii}
  def encoding_from_byte(0x01), do: {:ok, :extended_ascii}
  def encoding_from_byte(0x02), do: {:ok, :utf_16}

  def encoding_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :encoding, command: :node_name_set}}
end
