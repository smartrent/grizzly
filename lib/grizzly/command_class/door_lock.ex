defmodule Grizzly.CommandClass.DoorLock do
  @moduledoc """
  Functions and types for working with data found found in the door lock command
  class.
  """

  @typedoc """
  A type to represent the different door lock modes

  - `:secured` - an alias to `0xFF`
  - `:unsecured` - an alias to `0x00`
  - `0x00` - unsecured
  - `0x01` - unsecured with timeout
  - `0x10` - unsecured inside door handles
  - `0x11` - unsecured inside door handles with timeout
  - `0x20` - unsecured for outside door handles
  - `0x21` - unsecured for outside door handles with timeout
  - `0xFF` - secured
  """
  @type door_lock_mode :: :secured | :unsecured | door_lock_mode_byte()

  @type door_lock_mode_byte :: 0x00 | 0x01 | 0x10 | 0x11 | 0x20 | 0x21 | 0xFF

  @type decoded_mode :: :secured | :unsecured | 0x01 | 0x10 | 0x11 | 0x20 | 0x21

  @modes [0x00, 0x01, 0x10, 0x11, 0x20, 0x21, 0xFF]

  @spec encode_mode(door_lock_mode) :: door_lock_mode_byte()
  def encode_mode(:secured), do: 0xFF
  def encode_mode(:unsecured), do: 0x00
  def encode_mode(door_lock_mode) when door_lock_mode in @modes, do: door_lock_mode

  @spec decode_mode(door_lock_mode_byte) :: decoded_mode()
  def decode_mode(0xFF), do: :secured
  def decode_mode(0x00), do: :unsecured
  def decode_mode(mode) when mode in @modes, do: mode
end
