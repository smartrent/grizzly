defmodule Grizzly.ZWave.Commands.DoorLockConfigurationReport do
  @moduledoc """
  This command is used to advertise the configuration parameters of a door lock device.

  Params:

    * `:operation_type` - the operation type at the supporting node. One of :constant_operation and :timed_operation. (required)

    * `:manual_outside_door_handles` - List of outside handles (1..4) that can open locally (required)

    * `:manual_inside_door_handles` - List of inside handles (1..4) that can open locally (required)

    * `:lock_timeout` - The seconds that the supporting node must wait before returning to the secured
                        mode when receiving timed operation modes in a Door Lock Operation Set Command (required)

    * `:auto_relock_time` - The time setting in seconds for auto-relock functionality. (v.4 only)

    * `:hold_and_release_time` - The time setting in seconds for letting the latch retracted after the
                                 supporting node’s mode has been changed to unsecured. (v.4 only)

    * `:twist_assist?` - Indicates if the twist assist functionality is enabled. (v.4 only)

    * `:block_to_block?` - Indicates if the block-to-block functionality is enabled. (v.4 only)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:operation_type, DoorLock.operation_type()}
          | {:manual_outside_door_handles, [1..4]}
          | {:manual_inside_door_handles, [1..4]}
          | {:lock_timeout, non_neg_integer()}
          | {:auto_relock_time, non_neg_integer}
          | {:hold_and_release_time, non_neg_integer}
          | {:twist_assist?, boolean}
          | {:block_to_block?, boolean}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :door_lock_configuration_report,
      command_byte: 0x06,
      command_class: DoorLock,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    operation_type_byte =
      Command.param!(command, :operation_type) |> DoorLock.operation_type_to_byte()

    manual_outside_door_handles_bitmask =
      Command.param!(command, :manual_outside_door_handles) |> DoorLock.door_handles_to_bitmask()

    manual_inside_door_handles_bitmask =
      Command.param!(command, :manual_inside_door_handles) |> DoorLock.door_handles_to_bitmask()

    {lock_timeout_mins, lock_timeout_secs} =
      Command.param!(command, :lock_timeout) |> DoorLock.to_minutes_and_seconds()

    common_binary =
      <<operation_type_byte, manual_outside_door_handles_bitmask::4,
        manual_inside_door_handles_bitmask::4, lock_timeout_mins, lock_timeout_secs>>

    auto_relock_time = Command.param(command, :auto_relock_time)

    if auto_relock_time == nil do
      common_binary
    else
      # v.4
      hold_and_release_time = Command.param!(command, :hold_and_release_time)
      block_to_block_bit = if Command.param!(command, :block_to_block?), do: 0x01, else: 0x00
      twist_assist_bit = if Command.param!(command, :twist_assist?), do: 0x01, else: 0x00

      common_binary <>
        <<auto_relock_time::16, hold_and_release_time::16, 0x00::6, block_to_block_bit::1,
          twist_assist_bit::1>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # v1-3
  def decode_params(
        <<operation_type_byte, manual_outside_door_handles_bitmask::4,
          manual_inside_door_handles_bitmask::4, lock_timeout_mins, lock_timeout_secs>>
      ) do
    with {:ok, operation_type} <- DoorLock.operation_type_from_byte(operation_type_byte) do
      lock_timeout = 60 * lock_timeout_mins + lock_timeout_secs

      manual_outside_door_handles =
        DoorLock.door_handles_from_bitmask(manual_outside_door_handles_bitmask)

      manual_inside_door_handles =
        DoorLock.door_handles_from_bitmask(manual_inside_door_handles_bitmask)

      {:ok,
       [
         operation_type: operation_type,
         manual_outside_door_handles: manual_outside_door_handles,
         manual_inside_door_handles: manual_inside_door_handles,
         lock_timeout: lock_timeout
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :door_lock_configuration_report}}
    end
  end

  # v4
  def decode_params(
        <<operation_type_byte, manual_outside_door_handles_bitmask::4,
          manual_inside_door_handles_bitmask::4, lock_timeout_mins, lock_timeout_secs,
          auto_relock_time::16, hold_and_release_time::16, _reserved::6, block_to_block_bit::1,
          twist_assist_bit::1>>
      ) do
    with {:ok, operation_type} <- DoorLock.operation_type_from_byte(operation_type_byte) do
      lock_timeout = 60 * lock_timeout_mins + lock_timeout_secs

      manual_outside_door_handles =
        DoorLock.door_handles_from_bitmask(manual_outside_door_handles_bitmask)

      manual_inside_door_handles =
        DoorLock.door_handles_from_bitmask(manual_inside_door_handles_bitmask)

      {:ok,
       [
         operation_type: operation_type,
         manual_outside_door_handles: manual_outside_door_handles,
         manual_inside_door_handles: manual_inside_door_handles,
         lock_timeout: lock_timeout,
         auto_relock_time: auto_relock_time,
         hold_and_release_time: hold_and_release_time,
         block_to_block?: block_to_block_bit == 1,
         twist_assist?: twist_assist_bit == 1
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :door_lock_configuration_report}}
    end
  end
end
