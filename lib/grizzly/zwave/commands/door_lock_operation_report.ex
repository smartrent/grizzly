defmodule Grizzly.ZWave.Commands.DoorLockOperationReport do
  @moduledoc """
  OperationReport is used to advertise the status of a door lock

  This is response to the `Grizzly.ZWave.Commands.OperationGet`
  command.

  Params:

    * `:mode` - the door operating lock mode (required)
    * `:outside_handles_mode` - a map of the outside door handles and if they
      can or cannot open the door locally (optional)
    * `:inside_handles_mode` - a map of the inside door handles and if they can
      or cannot open the door locally (optional)
    * `:latch_position` - the position of the latch (optional)
    * `:bolt_position` - the position of the bolt (optional)
    * `:door_state` - the state of the door being open or closed (optional)
    * `:timeout_minutes` - how long the door has been unlocked (required)
    * `:timeout_seconds` - how long the door has been unlocked (required)
    * `:target_mode` - the target mode of an ongoing transition or of the most recent transition (optional - v4)
    * `duration` - the estimated remaining time before the target mode is realized (optional - v4)
  """

  @behaviour Grizzly.ZWave.Command

  require Logger
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.DoorLock

  @typedoc """
  These modes tell if the handle can open the door locally or not.

  The door lock does not have to report all or any of these, so the default is
  to set them all to disabled if they are not specified when building the
  command.
  """
  @type handles_mode :: %{non_neg_integer() => :enabled | :disabled}

  @typedoc """
  This param only matters if the door lock says it supports this door
  component in the CapabilitiesReport.

  If it isn't support the node receiving this report can ignore.

  For defaults, if this param isn't provided during when calling `new/1`, we
  0 this field out by setting it to :disabled
  """
  @type latch_position :: :open | :closed

  @typedoc """
  This param only matters if the door lock says it supports this door
  component in the CapabilitiesReport.

  If it isn't support the node receiving this report can ignore.

  For defaults, if this param isn't provided during when calling `new/1`, we
  0 this field out by setting it to :disabled
  """
  @type bolt_position :: :locked | :unlocked

  @typedoc """
  This param only matters if the door lock says it supports this door
  component in the CapabilitiesReport.

  If it isn't support the node receiving this report can ignore.

  For defaults, if this param isn't provided during when calling `new/1`, we
  0 this field out by setting it to :disabled
  """
  @type door_state :: :open | :closed

  @type timeout_minutes :: 0x00..0xFD | :undefined

  @type timeout_seconds :: 0x00..0x3B | :undefined

  @type param ::
          {:mode, DoorLock.mode()}
          | {:outside_handles_mode, handles_mode()}
          | {:inside_handles_mode, handles_mode()}
          | {:latch_position, latch_position()}
          | {:bolt_position, bolt_position()}
          | {:door_state, door_state()}
          | {:timeout_minutes, timeout_minutes()}
          | {:timeout_seconds, timeout_seconds()}
          | {:target_mode, DoorLock.mode()}
          | {:duration, :unknown | non_neg_integer()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :door_lock_operation_report,
      command_byte: 0x03,
      command_class: DoorLock,
      params: params_with_defaults(params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mode = Command.param!(command, :mode)
    outside_door_handles = Command.param!(command, :outside_handles_mode)
    inside_door_handles = Command.param!(command, :inside_handles_mode)
    latch_position = Command.param!(command, :latch_position)
    bolt_position = Command.param!(command, :bolt_position)
    door_state = Command.param!(command, :door_state)
    timeout_minutes = Command.param!(command, :timeout_minutes)
    timeout_seconds = Command.param!(command, :timeout_seconds)
    target_mode = Command.param(command, :target_mode)
    outside_handles_byte = door_handles_modes_to_byte(outside_door_handles)
    inside_handles_byte = door_handles_modes_to_byte(inside_door_handles)
    door_condition_byte = door_condition_to_byte(latch_position, bolt_position, door_state)
    timeout_minutes_byte = timeout_minutes_to_byte(timeout_minutes)
    timeout_seconds_byte = timeout_seconds_to_byte(timeout_seconds)

    <<handles_byte>> = <<outside_handles_byte::size(4), inside_handles_byte::size(4)>>

    if target_mode == nil do
      <<DoorLock.mode_to_byte(mode), handles_byte, door_condition_byte, timeout_minutes_byte,
        timeout_seconds_byte>>
    else
      # version 4
      duration = Command.param!(command, :duration)
      target_mode_byte = DoorLock.mode_to_byte(target_mode)
      duration_byte = duration_to_byte(duration)

      <<DoorLock.mode_to_byte(mode), handles_byte, door_condition_byte, timeout_minutes_byte,
        timeout_seconds_byte, target_mode_byte, duration_byte>>
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<mode_byte, outside_handles_int::size(4), inside_handles_int::size(4),
          door_condition_byte, timeout_minutes, timeout_seconds>>
      ) do
    outside_handles = door_handles_modes_from_byte(outside_handles_int)
    inside_handles = door_handles_modes_from_byte(inside_handles_int)
    latch_position = latch_position_from_byte(door_condition_byte)
    bolt_position = bolt_position_from_byte(door_condition_byte)
    door_state = door_state_from_byte(door_condition_byte)
    mode = DoorLock.mode_from_byte(mode_byte)

    with {:ok, timeout_minutes} <- timeout_minutes_from_byte(timeout_minutes),
         {:ok, timeout_seconds} <- timeout_seconds_from_byte(timeout_seconds) do
      {:ok,
       [
         mode: mode,
         outside_handles_mode: outside_handles,
         inside_handles_mode: inside_handles,
         latch_position: latch_position,
         bolt_position: bolt_position,
         door_state: door_state,
         timeout_minutes: timeout_minutes,
         timeout_seconds: timeout_seconds
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :door_lock_operation_report}}
    end
  end

  # This is to support a lock that erroneously omits the timeout_seconds field.
  def decode_params(bin) when byte_size(bin) == 4, do: decode_params(<<bin::binary, 0>>)

  # Version 4
  def decode_params(
        <<mode_byte, outside_handles_int::size(4), inside_handles_int::size(4),
          door_condition_byte, timeout_minutes, timeout_seconds, target_mode_byte, duration_byte,
          invalid_extra::binary>> = binary
      ) do
    if byte_size(invalid_extra) != 0 do
      Logger.warning("[Grizzly] Extra bytes in Door Lock Operation Report #{inspect(binary)}")
    end

    outside_handles = door_handles_modes_from_byte(outside_handles_int)
    inside_handles = door_handles_modes_from_byte(inside_handles_int)
    latch_position = latch_position_from_byte(door_condition_byte)
    bolt_position = bolt_position_from_byte(door_condition_byte)
    door_state = door_state_from_byte(door_condition_byte)
    mode = DoorLock.mode_from_byte(mode_byte)
    target_mode = DoorLock.mode_from_byte(target_mode_byte)

    with {:ok, timeout_minutes} <- timeout_minutes_from_byte(timeout_minutes),
         {:ok, timeout_seconds} <- timeout_seconds_from_byte(timeout_seconds),
         {:ok, duration} <- duration_from_byte(duration_byte) do
      {:ok,
       [
         mode: mode,
         outside_handles_mode: outside_handles,
         inside_handles_mode: inside_handles,
         latch_position: latch_position,
         bolt_position: bolt_position,
         door_state: door_state,
         timeout_minutes: timeout_minutes,
         timeout_seconds: timeout_seconds,
         target_mode: target_mode,
         duration: duration
       ]}
    end
  end

  def door_handles_modes_to_byte(handles_mode) do
    handle_1_bit = door_handle_value_to_bit(Map.get(handles_mode, 1, :disabled))
    handle_2_bit = door_handle_value_to_bit(Map.get(handles_mode, 2, :disabled))
    handle_3_bit = door_handle_value_to_bit(Map.get(handles_mode, 3, :disabled))
    handle_4_bit = door_handle_value_to_bit(Map.get(handles_mode, 4, :disabled))

    <<byte>> =
      <<0::size(4), handle_4_bit::size(1), handle_3_bit::size(1), handle_2_bit::size(1),
        handle_1_bit::size(1)>>

    byte
  end

  def door_condition_to_byte(latch_position, bolt_position, door_state) do
    latch_bit = latch_bit_from_position(latch_position)
    bolt_bit = bolt_bit_from_position(bolt_position)
    door_bit = door_bit_from_state(door_state)

    <<byte>> = <<0::size(5), latch_bit::size(1), bolt_bit::size(1), door_bit::size(1)>>

    byte
  end

  defp params_with_defaults(params) do
    handles_modes_default = %{1 => :disabled, 2 => :disabled, 3 => :disabled, 4 => :disabled}

    defaults = [
      inside_handles_mode: handles_modes_default,
      outside_handles_mode: handles_modes_default,
      latch_position: :open,
      bolt_position: :locked,
      door_state: :open,
      timeout_minutes: 0,
      timeout_seconds: 0
    ]

    Keyword.merge(defaults, params)
  end

  defp latch_bit_from_position(:open), do: 0
  defp latch_bit_from_position(:closed), do: 1

  defp bolt_bit_from_position(:locked), do: 0
  defp bolt_bit_from_position(:unlocked), do: 1

  defp door_bit_from_state(:open), do: 0
  defp door_bit_from_state(:closed), do: 1

  defp timeout_seconds_to_byte(s) when s >= 0 and s <= 0x3B, do: s
  defp timeout_seconds_to_byte(:undefined), do: 0xFE

  defp timeout_minutes_to_byte(m) when m >= 0 and m <= 0xFC, do: m
  defp timeout_minutes_to_byte(:undefined), do: 0xFE

  defp duration_to_byte(secs) when secs in 0..127, do: secs
  defp duration_to_byte(secs) when secs in 128..(126 * 60), do: round(secs / 60) + 0x7F
  defp duration_to_byte(:unknown), do: 0xFE

  @spec door_handles_modes_from_byte(byte()) :: %{(1..4) => :enabled | :disabled}
  defp door_handles_modes_from_byte(byte) do
    <<_::size(4), handle_4::size(1), handle_3::size(1), handle_2::size(1), handle_1::size(1)>> =
      <<byte>>

    %{
      1 => door_handle_enable_value_from_bit(handle_1),
      2 => door_handle_enable_value_from_bit(handle_2),
      3 => door_handle_enable_value_from_bit(handle_3),
      4 => door_handle_enable_value_from_bit(handle_4)
    }
  end

  @spec door_handle_enable_value_from_bit(0 | 1) :: :enabled | :disabled
  defp door_handle_enable_value_from_bit(1), do: :enabled
  defp door_handle_enable_value_from_bit(0), do: :disabled

  defp door_handle_value_to_bit(:enabled), do: 1
  defp door_handle_value_to_bit(:disabled), do: 0

  @spec latch_position_from_byte(byte()) :: latch_position()
  defp latch_position_from_byte(byte) do
    <<_::size(5), latch_bit::size(1), _::size(2)>> = <<byte>>

    if latch_bit == 1 do
      :closed
    else
      :open
    end
  end

  @spec bolt_position_from_byte(byte()) :: bolt_position()
  defp bolt_position_from_byte(byte) do
    <<_::size(5), _::size(1), bolt_bit::size(1), _::size(1)>> = <<byte>>

    if bolt_bit == 1 do
      :unlocked
    else
      :locked
    end
  end

  @spec door_state_from_byte(byte()) :: door_state()
  defp door_state_from_byte(byte) do
    <<_::size(5), _::size(2), door_state_bit::size(1)>> = <<byte>>

    if door_state_bit == 1 do
      :closed
    else
      :open
    end
  end

  @spec timeout_minutes_from_byte(byte()) :: {:ok, timeout_minutes()} | {:error, DecodeError.t()}
  defp timeout_minutes_from_byte(m) when m >= 0 and m <= 0xFD, do: {:ok, m}
  defp timeout_minutes_from_byte(0xFE), do: {:ok, :undefined}

  defp timeout_minutes_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :timeout_minute, command: :operation_report}}

  @spec timeout_seconds_from_byte(byte()) :: {:ok, timeout_seconds()} | {:error, DecodeError.t()}
  defp timeout_seconds_from_byte(s) when s >= 0 and s <= 0x3B, do: {:ok, s}
  defp timeout_seconds_from_byte(0xFE), do: {:ok, :undefined}

  defp timeout_seconds_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :timeout_second, command: :operation_report}}

  @spec duration_from_byte(byte()) ::
          {:ok, :unknown | non_neg_integer()} | {:error, DecodeError.t()}
  defp duration_from_byte(byte) when byte in 0x00..0x7F, do: {:ok, byte}
  defp duration_from_byte(byte) when byte in 0x80..0xFD, do: {:ok, (byte - 0x7F) * 60}
  defp duration_from_byte(0xFE), do: {:ok, :unknown}

  defp duration_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :duration, command: :supervision_report}}
end
