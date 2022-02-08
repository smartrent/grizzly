defmodule Grizzly.ZWave.Commands.PowerlevelSet do
  @moduledoc """
  This command is used to set the power level indicator value, which should be
  used by the node when transmitting RF, and the timeout for this power level
  indicator value before returning the power level defined by the application.

  Params:

    * `:power_level` - This field indicates the power level value that the
      receiving node MUST set.
    * `:reset_timeout` - The time in seconds the node should keep the Power level
      before resetting to normalPower level.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @type param :: {:power_level, Powerlevel.power_level()} | {:reset_timeout, non_neg_integer()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :powerlevel_set,
      command_byte: 0x01,
      command_class: Powerlevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    power_level_byte = Command.param!(command, :power_level) |> Powerlevel.power_level_to_byte()
    reset_timeout = Command.param!(command, :reset_timeout)
    <<power_level_byte, reset_timeout>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<power_level_byte, reset_timeout>>) do
    with {:ok, power_level} <- Powerlevel.power_level_from_byte(power_level_byte) do
      {:ok, [power_level: power_level, reset_timeout: reset_timeout]}
    else
      {:error, %DecodeError{} = error} ->
        %DecodeError{error | command: :powerlevel_set}
    end
  end
end
