defmodule Grizzly.ZWave.Commands.SwitchMultilevelStartLevelChange do
  @moduledoc """
  Module for the SWITCH_MULTILEVEL_START_LEVEL_CHANGE

  Params:

    * `:up_down` - initiating change of level :up or :down
    * `:duration` - seconds to take to go from 0 to 99, or 99 to 0 - optional v2

    Note that support for secodary switch introduced in v3 is deprecated and ignored here.
    A controller SHOULD ignore Start Level; it is always ignored here.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.SwitchMultilevel

  @type param :: {:up_down, :up | :down} | {:duration, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :switch_multilevel_start_level_change,
      command_byte: 0x04,
      command_class: SwitchMultilevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    up_down = encode_up_down(Command.param!(command, :up_down))

    case Command.param(command, :duration) do
      nil ->
        <<
          # Reserved
          0x00::size(1),
          up_down::size(1),
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::size(1),
          # Reserved
          0x00::size(5),
          # Start level is ignored
          0x00
        >>

      # v2
      duration ->
        <<
          # Reserved
          0x00::size(1),
          up_down::size(1),
          # A controlling device SHOULD set the Ignore Start Level bit to 1.
          0x01::size(1),
          # Reserved
          0x00::size(5),
          # Start level is ignored
          0x00,
          duration::size(8)
        >>
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<
        # Reserved
        _reserved::size(1),
        up_down_byte::size(1),
        # A controlling device SHOULD set the Ignore Start Level bit to 1.
        0x01::size(1),
        # Reserved
        _other_reserved::size(5),
        # Start level is ignored
        _start_level
      >>) do
    {:ok, [up_down: decode_up_down(up_down_byte)]}
  end

  # v2
  def decode_params(<<
        # Reserved
        _reserved::size(1),
        up_down::size(1),
        # A controlling device SHOULD set the Ignore Start Level bit to 1.
        0x01::size(1),
        # Reserved
        _other_reserved::size(5),
        # Start level is ignored
        _start_level,
        duration,
        _rest::binary()
      >>) do
    {:ok, [up_down: decode_up_down(up_down), duration: duration]}
  end

  def encode_up_down(:up), do: 0x00
  def encode_up_down(:down), do: 0x01

  def decode_up_down(0x00), do: :up
  def decode_up_down(0x01), do: :down
end
