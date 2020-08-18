defmodule Grizzly.ZWave.Commands.IndicatorGet do
  @moduledoc """
  This command is used to request the state of an indicator.

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required for v2)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Indicator

  @type param :: {:indicator_id, Indicator.indicator_id()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_get,
      command_byte: 0x02,
      command_class: Indicator,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    indicator_id = Command.param(command, :indicator_id)

    if indicator_id == nil do
      <<>>
    else
      indicator_id_byte = Indicator.indicator_id_to_byte(indicator_id)
      <<indicator_id_byte>>
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<>>) do
    {:ok, []}
  end

  def decode_params(<<indicator_id_byte>>) do
    with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte) do
      {:ok, [indicator_id: indicator_id]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :indicator_get}}
    end
  end
end
