defmodule Grizzly.ZWave.Commands.IndicatorDescriptionGet do
  @moduledoc """
  This command is used to request a detailed description of the appearance and use of an Indicator ID

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Indicator

  @type param :: {:indicator_id, Indicator.indicator_id()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_description_get,
      command_byte: 0x06,
      command_class: Indicator,
      params: params,
      impl: __MODULE__
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
        {:error, %DecodeError{decode_error | command: :indicator_description_get}}
    end
  end
end
