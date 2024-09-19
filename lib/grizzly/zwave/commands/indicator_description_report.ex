defmodule Grizzly.ZWave.Commands.IndicatorDescriptionReport do
  @moduledoc """
  This command is used to advertise appearance and use of an indicator ID resource.

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required)

    * `:description` - This field is used to advertise the appearance and use of the Indicator ID

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Indicator

  @type param :: {:indicator_id, Indicator.indicator_id()} | {:description, String.t()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_description_report,
      command_byte: 0x07,
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
    description = Command.param!(command, :description)
    size = byte_size(description)
    <<indicator_id_byte, size>> <> description
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<indicator_id_byte, _size, description::binary>>) do
    with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte) do
      {:ok, [indicator_id: indicator_id, description: description]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :indicator_description_report}}
    end
  end
end
