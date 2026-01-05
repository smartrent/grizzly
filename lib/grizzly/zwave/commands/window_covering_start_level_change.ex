defmodule Grizzly.ZWave.Commands.WindowCoveringStartLevelChange do
  @moduledoc """
  This command is used to initiate a transition of one parameter to a new level.

  Params:

  * `:parameter_name` - the parameter's name (see Grizzly.ZWave.CommandClasses.WindowCovering for options)

  * `:direction` - the direction of the level change (:up or :down)

  * `:duration` - the duration of the change

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WindowCovering
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:direction, :up | :down}
          | {:parameter_name, WindowCovering.parameter_name()}
          | {:duration, byte()}
  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :window_covering_start_level_change,
      command_byte: 0x06,
      command_class: WindowCovering,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    parameter_id =
      Command.param!(command, :parameter_name) |> WindowCovering.encode_parameter_name()

    direction_bit = Command.param!(command, :direction) |> encode_direction()
    duration = Command.param!(command, :duration)
    <<0x00::1, direction_bit::1, 0x00::6, parameter_id, duration>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved::1, direction_bit::1, _also_reserved::6, parameter_id, duration>>) do
    case WindowCovering.decode_parameter_name(parameter_id) do
      {:ok, parameter_name} ->
        direction = decode_direction(direction_bit)
        {:ok, [parameter_name: parameter_name, direction: direction, duration: duration]}

      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :window_covering_start_level_change}}
    end
  end

  defp encode_direction(:up), do: 0x00
  defp encode_direction(:down), do: 0x01

  defp decode_direction(0x00), do: :up
  defp decode_direction(0x01), do: :down
end
