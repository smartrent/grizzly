defmodule Grizzly.ZWave.CommandClasses.BarrierOperator do
  @moduledoc """
  "BarrierOperator" Command Class

  The Barrier Operator Command Class is used to control and query the status of motorized barriers.
  """

  import Bitwise

  alias Grizzly.ZWave.DecodeError

  @type target_value :: :open | :close
  @type state :: :closed | 0x01..0x63 | :closing | :stopped | :opening | :open
  @type subsystem_type :: :audible_notification | :visual_notification
  @type subsystem_state :: :on | :off

  @spec target_value_to_byte(:close | :open) :: 0x00 | 0xFF
  def target_value_to_byte(:close), do: 0x00
  def target_value_to_byte(:open), do: 0xFF

  @spec target_value_from_byte(byte) ::
          {:error, Grizzly.ZWave.DecodeError.t()} | {:ok, :close | :open}
  def target_value_from_byte(0x00), do: {:ok, :close}
  def target_value_from_byte(0xFF), do: {:ok, :open}
  def target_value_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :target_value}}

  @spec state_to_byte(state) :: byte
  def state_to_byte(:closed), do: 0x00
  def state_to_byte(:closing), do: 0xFC
  def state_to_byte(:stopped), do: 0xFD
  def state_to_byte(:opening), do: 0xFE
  def state_to_byte(:open), do: 0xFF
  def state_to_byte(stopped_position) when stopped_position in 0x01..0x63, do: stopped_position

  @spec state_from_byte(byte) ::
          {:error, Grizzly.ZWave.DecodeError.t()}
          | {:ok, state}
  def state_from_byte(0x00), do: {:ok, :closed}
  def state_from_byte(0xFC), do: {:ok, :closing}
  def state_from_byte(0xFD), do: {:ok, :stopped}
  def state_from_byte(0xFE), do: {:ok, :opening}
  def state_from_byte(0xFF), do: {:ok, :open}
  def state_from_byte(byte) when byte in 0x01..0x63, do: {:ok, byte}
  def state_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :state}}

  @doc "Converts subsystems into a bytes"
  @spec subsystem_types_to_bitmask([subsystem_type]) :: byte
  def subsystem_types_to_bitmask(subsystem_types) do
    subsystem_type_bytes =
      for subsystem_type <- subsystem_types, do: subsystem_type_to_byte(subsystem_type)

    integer = Enum.reduce(subsystem_type_bytes, 0x00, fn byte, acc -> acc ||| byte end)
    <<byte>> = <<integer>>
    byte
  end

  def bitmask_to_subsystem_types(byte) do
    bitmask = <<byte>>

    bits_on =
      for(<<x::1 <- bitmask>>, do: x)
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.reduce([], fn {bit, index}, acc ->
        if bit == 1, do: [index | acc], else: acc
      end)

    Enum.reduce(bits_on, [], fn bit_on, acc ->
      case subsystem_type_from_byte(bit_on) do
        {:ok, subsystem_type} -> [subsystem_type | acc]
        _other -> acc
      end
    end)
  end

  @spec subsystem_type_to_byte(:audible_notification | :visual_notification) :: 0x01 | 0x02
  def subsystem_type_to_byte(:audible_notification), do: 0x01
  def subsystem_type_to_byte(:visual_notification), do: 0x02

  @spec subsystem_type_from_byte(any) ::
          {:error, Grizzly.ZWave.DecodeError.t()}
          | {:ok, subsystem_type}
  def subsystem_type_from_byte(0x01), do: {:ok, :audible_notification}
  def subsystem_type_from_byte(0x02), do: {:ok, :visual_notification}

  def subsystem_type_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :subsystem_type}}

  @spec subsystem_state_to_byte(:off | :on) :: 0x00 | 0xFF
  def subsystem_state_to_byte(:off), do: 0x00
  def subsystem_state_to_byte(:on), do: 0xFF

  @spec subsystem_state_from_byte(byte) ::
          {:error, Grizzly.ZWave.DecodeError.t()} | {:ok, subsystem_state}
  def subsystem_state_from_byte(0x00), do: {:ok, :off}
  def subsystem_state_from_byte(0xFF), do: {:ok, :on}

  def subsystem_state_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :subsystem_state}}
end
