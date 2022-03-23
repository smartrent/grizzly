defmodule Grizzly.ZWave.Commands.WindowCoveringStopLevelChange do
  @moduledoc """
  This command is used to stop an ongoing transition.

  Params:

    * `:parameter_name` - the parameter's name (see Grizzly.ZWave.CommandClasses.WindowCovering for options)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.WindowCovering

  @type param :: {:parameter_id, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :window_covering_stop_level_change,
      command_byte: 0x07,
      command_class: WindowCovering,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    parameter_id =
      Command.param!(command, :parameter_name) |> WindowCovering.encode_parameter_name()

    <<parameter_id>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<parameter_id>>) do
    case WindowCovering.decode_parameter_name(parameter_id) do
      {:ok, parameter_name} ->
        {:ok, [parameter_name: parameter_name]}

      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :window_covering_get}}
    end
  end
end
