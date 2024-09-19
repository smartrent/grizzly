defmodule Grizzly.ZWave.CommandClasses.DoorLock do
  @moduledoc """
  DoorLock Command Class

  This command class provides commands that are used to operate and configure
  door lock devices
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  require Logger

  @type mode ::
          :unsecured
          | :unsecured_with_timeout
          | :unsecured_inside_door_handles
          | :unsecured_inside_door_handles_with_timeout
          | :unsecured_outside_door_handles
          | :unsecured_outside_door_handles_with_timeout
          | :secured
          | :unknown

  @type operation_type :: :constant_operation | :timed_operation

  @type door_components :: :bolt | :latch | :door

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x62

  @impl Grizzly.ZWave.CommandClass
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

  @spec mode_from_byte(byte()) :: mode()
  def mode_from_byte(0x00), do: :unsecured
  def mode_from_byte(0x01), do: :unsecured_with_timeout
  def mode_from_byte(0x10), do: :unsecured_inside_door_handles
  def mode_from_byte(0x11), do: :unsecured_inside_door_handles_with_timeout
  def mode_from_byte(0x20), do: :unsecured_outside_door_handles
  def mode_from_byte(0x21), do: :unsecured_outside_door_handles_with_timeout
  def mode_from_byte(0xFF), do: :secured
  # version >= 4
  def mode_from_byte(0xFE), do: :unknown

  def mode_from_byte(byte) do
    Logger.warning("Unexpected value for door lock mode: #{byte}")
    :unknown
  end

  def operation_type_to_byte(:constant_operation), do: 0x01
  def operation_type_to_byte(:timed_operation), do: 0x02

  def operation_type_from_byte(0x01), do: {:ok, :constant_operation}
  def operation_type_from_byte(0x02), do: {:ok, :timed_operation}

  def operation_type_from_byte(byte),
    do: {:error, %DecodeError{param: :operation_type, value: byte}}

  def door_handles_to_bitmask(handles) do
    <<bitmask::4>> =
      for handle <- 4..1//-1, into: <<>> do
        if handle in handles, do: <<0x01::1>>, else: <<0x00::1>>
      end

    bitmask
  end

  def door_handles_from_bitmask(byte) do
    bitmask = <<byte::4>>

    for(<<x::1 <- bitmask>>, do: x)
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {bit, index}, acc ->
      if bit == 1, do: [index | acc], else: acc
    end)
  end

  def to_minutes_and_seconds(seconds) do
    {div(seconds, 60), rem(seconds, 60)}
  end
end
