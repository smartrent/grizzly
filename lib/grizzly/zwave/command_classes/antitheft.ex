defmodule Grizzly.ZWave.CommandClasses.Antitheft do
  @moduledoc """
  "Antitheft" Command Class

  This Command Class is used to lock (and possibly unlock) a node.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type lock_state :: :locked | :unlocked
  @type status ::
          :protection_disabled_unlocked
          | :protection_enabled_locked_fully_functional
          | :protection_enabled_locked_restricted

  @impl true
  def byte(), do: 0x5D

  @impl true
  def name(), do: :antitheft

  def state_to_bit(:unlocked), do: 0x00
  def state_to_bit(:locked), do: 0x01

  def state_from_bit(0x00), do: :unlocked
  def state_from_bit(0x01), do: :locked

  def status_to_byte(:protection_disabled_unlocked), do: 0x01
  def status_to_byte(:protection_enabled_locked_fully_functional), do: 0x02
  def status_to_byte(:protection_enabled_locked_restricted), do: 0x03

  def status_from_byte(0x01), do: {:ok, :protection_disabled_unlocked}
  def status_from_byte(0x02), do: {:ok, :protection_enabled_locked_fully_functional}
  def status_from_byte(0x03), do: {:ok, :protection_enabled_locked_restricted}
  def status_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :status}}

  def validate_magic_code_or_hint(magic_code_or_hint) when is_binary(magic_code_or_hint) do
    true = String.length(magic_code_or_hint) in 1..10
    magic_code_or_hint
  end
end
