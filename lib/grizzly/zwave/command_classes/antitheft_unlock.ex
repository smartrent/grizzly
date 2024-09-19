defmodule Grizzly.ZWave.CommandClasses.AntitheftUnlock do
  @moduledoc """
  "AntitheftUnlock" Command Class

  This Command Class is used to unlock a device that has been locked by the Anti-theft Command Class.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @type state :: :locked | :unlocked

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x7E

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :antitheft_unlock

  def state_to_bit(:unlocked), do: 0x00
  def state_to_bit(:locked), do: 0x01

  def state_from_bit(0x00), do: :unlocked
  def state_from_bit(0x01), do: :locked

  def validate_hint(hint) when is_binary(hint) do
    true = byte_size(hint) <= 10
    hint
  end

  def validate_magic_code(magic_code) when is_binary(magic_code) do
    true = byte_size(magic_code) in 1..10
    magic_code
  end
end
