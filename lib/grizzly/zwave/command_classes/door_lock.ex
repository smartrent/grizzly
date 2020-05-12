defmodule Grizzly.ZWave.CommandClasses.DoorLock do
  @moduledoc """
  DoorLock Command Class

  This command class provides commands that are used to operate and configure
  door lock devices
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type mode ::
          :unsecured
          | :unsecured_with_timeout
          | :unsecured_inside_door_handles
          | :unsecured_inside_door_handles_with_timeout
          | :unsecured_outside_door_handles
          | :unsecured_outside_door_handles_with_timeout
          | :secured
          | :unknown

  @impl true
  def byte(), do: 0x62

  @impl true
  def name(), do: :door_lock

  @spec mode_to_byte(mode()) :: byte()
  def mode_to_byte(:unsecured), do: 0x00
  def mode_to_byte(:unsecured_with_timeout), do: 0x01
  def mode_to_byte(:unsecured_inside_door_handles), do: 0x10
  def mode_to_byte(:unsecured_inside_door_handles_with_timeout), do: 0x11
  def mode_to_byte(:unsecured_outside_door_handles), do: 0x20
  def mode_to_byte(:unsecured_outside_door_handles_with_timeout), do: 0x21
  def mode_to_byte(:secured), do: 0xFF
  # version >= 4
  def mode_to_byte(:unknown), do: 0xFE

  @spec mode_from_byte(byte()) :: {:ok, mode()} | {:error, DecodeError.t()}
  def mode_from_byte(0x00), do: {:ok, :unsecured}
  def mode_from_byte(0x01), do: {:ok, :unsecured_with_timeout}
  def mode_from_byte(0x10), do: {:ok, :unsecured_inside_door_handles}
  def mode_from_byte(0x11), do: {:ok, :unsecured_inside_door_handles_with_timeout}
  def mode_from_byte(0x20), do: {:ok, :unsecured_outside_door_handles}
  def mode_from_byte(0x21), do: {:ok, :unsecured_outside_door_handles_with_timeout}
  def mode_from_byte(0xFF), do: {:ok, :secured}
  # version >= 4
  def mode_from_byte(0xFE), do: {:ok, :unknown}

  def mode_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :operation_set}}
end
