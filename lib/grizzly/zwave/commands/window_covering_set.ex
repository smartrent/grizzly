defmodule Grizzly.ZWave.Commands.WindowCoveringSet do
  @moduledoc """
  This command is used to control one or more parameters in a window covering device.

  Params:

    * `:parameters` - The parameters to be set

    * `:duration` - specifies the time that the transition should take from the current value to the new target value.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.WindowCovering

  @type parameter :: {:name, WindowCovering.parameter_name()} | {:value, parameter_value()}
  @type parameter_value :: byte()
  @type param :: {:parameters, [parameter()]} | {:duration, byte()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :window_covering_set,
      command_byte: 0x05,
      command_class: WindowCovering,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    parameters = Command.param!(command, :parameters)
    duration = Command.param!(command, :duration)
    parameters_binary = parameters_to_binary(parameters)
    <<0x00::3, Enum.count(parameters)::size(5)>> <> parameters_binary <> <<duration>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<0x00::4, parameters_count::4, rest::binary>>) do
    parameters_size = parameters_count * 2
    <<parameters_binary::binary-size(parameters_size), duration>> = rest

    try do
      parameters = parameters_from_binary(parameters_binary)
      {:ok, [duration: duration, parameters: parameters]}
    catch
      {:error, error} -> {:error, error}
    end
  end

  defp parameters_to_binary(parameters) do
    for parameter <- parameters, into: <<>> do
      id = Keyword.fetch!(parameter, :name) |> WindowCovering.encode_parameter_name()
      value = Keyword.fetch!(parameter, :value)
      <<id, value>>
    end
  end

  defp parameters_from_binary(parameters_binary) do
    for <<id, value <- parameters_binary>>, into: [] do
      case WindowCovering.decode_parameter_name(id) do
        {:ok, parameter_name} ->
          [name: parameter_name, value: value]

        {:error, %DecodeError{} = error} ->
          throw({:error, %DecodeError{error | command: :window_covering_set}})
      end
    end
  end
end
