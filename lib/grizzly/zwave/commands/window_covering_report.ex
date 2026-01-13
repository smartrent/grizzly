defmodule Grizzly.ZWave.Commands.WindowCoveringReport do
  @moduledoc """
  his command is used to request the status of a specified Covering Parameter.

  Params:

    * `:parameter_name` - the parameter's name (see Grizzly.ZWave.CommandClasses.WindowCovering for options)
    * `:current_value` - the current value of the Parameter
    * `:target_value` - the target value of an ongoing transition or the most recent transition for the Parameter
    * `:duration` - the time needed to reach the Target Value at the actual transition rate
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WindowCovering
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:parameter_name, WindowCovering.parameter_name()}
          | {:current_value, byte()}
          | {:target_value, byte()}
          | {:duration, byte()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    parameter_id =
      Command.param!(command, :parameter_name) |> WindowCovering.encode_parameter_name()

    current_value = Command.param!(command, :current_value)
    target_value = Command.param!(command, :target_value)
    duration = Command.param!(command, :duration)
    <<parameter_id, current_value, target_value, duration>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<parameter_id, current_value, target_value, duration>>) do
    case WindowCovering.decode_parameter_name(parameter_id) do
      {:ok, parameter_name} ->
        {:ok,
         [
           parameter_name: parameter_name,
           current_value: current_value,
           target_value: target_value,
           duration: duration
         ]}

      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :window_covering_report}}
    end
  end
end
