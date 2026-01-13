defmodule Grizzly.ZWave.Commands.SwitchMultilevelStartLevelChange do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_START_LEVEL_CHANGE

  Params:

    * `:up_down` - initiating change of level :up or :down
    * `:duration` - seconds to take to go from 0 to 99, or 99 to 0 - optional v2

    Note that support for secondary switch introduced in v3 is deprecated and ignored here.
    A controller SHOULD ignore Start Level; it is always ignored here.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:up_down, :up | :down} | {:duration, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    up_down = encode_up_down(Command.param!(command, :up_down))

    case Command.param(command, :duration) do
      nil ->
        <<
          # Reserved
          0x00::1,
          up_down::1,
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::1,
          # Reserved
          0x00::5,
          # Start level is ignored
          0x00
        >>

      # v2
      duration ->
        <<
          # Reserved
          0x00::1,
          up_down::1,
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::1,
          # Reserved
          0x00::5,
          # Start level is ignored
          0x00,
          duration
        >>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<
          # Reserved
          _reserved::1,
          up_down_byte::1,
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::1,
          # Reserved
          _other_reserved::5,
          # Start level is ignored
          _start_level
        >>
      ) do
    {:ok, [up_down: decode_up_down(up_down_byte)]}
  end

  # v2
  def decode_params(
        _spec,
        <<
          # Reserved
          _reserved::1,
          up_down::1,
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::1,
          # Reserved
          _other_reserved::5,
          # Start level is ignored
          _start_level,
          duration,
          _rest::binary
        >>
      ) do
    {:ok, [up_down: decode_up_down(up_down), duration: duration]}
  end

  def encode_up_down(:up), do: 0x00
  def encode_up_down(:down), do: 0x01

  def decode_up_down(0x00), do: :up
  def decode_up_down(0x01), do: :down
end
