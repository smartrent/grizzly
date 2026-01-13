defmodule Grizzly.ZWave.Commands.WindowCoveringStopLevelChange do
  @moduledoc """
  This command is used to stop an ongoing transition.

  Params:

    * `:parameter_name` - the parameter's name (see Grizzly.ZWave.CommandClasses.WindowCovering for options)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WindowCovering
  alias Grizzly.ZWave.DecodeError

  @type param :: {:parameter_name, WindowCovering.parameter_name()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    parameter_id =
      Command.param!(command, :parameter_name) |> WindowCovering.encode_parameter_name()

    <<parameter_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<parameter_id>>) do
    case WindowCovering.decode_parameter_name(parameter_id) do
      {:ok, parameter_name} ->
        {:ok, [parameter_name: parameter_name]}

      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :window_covering_get}}
    end
  end
end
