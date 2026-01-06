defmodule Grizzly.ZWave.Commands.IndicatorSupportedGet do
  @moduledoc """
  This command is used to request the supported properties of an indicator.

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Indicator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:indicator_id, Indicator.indicator_id()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_supported_get,
      command_byte: 0x04,
      command_class: Indicator,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    indicator_id_byte = Command.param!(command, :indicator_id) |> Indicator.indicator_id_to_byte()
    <<indicator_id_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<indicator_id_byte>>) do
    with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte) do
      {:ok, [indicator_id: indicator_id]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :indicator_supported_get}}
    end
  end
end
