defmodule Grizzly.ZWave.Commands.IndicatorDescriptionGet do
  @moduledoc """
  This command is used to request a detailed description of the appearance and use of an Indicator ID

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Indicator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:indicator_id, Indicator.indicator_id()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    indicator_id_byte = Command.param!(command, :indicator_id) |> Indicator.indicator_id_to_byte()
    <<indicator_id_byte>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<indicator_id_byte>>) do
    with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte) do
      {:ok, [indicator_id: indicator_id]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :indicator_description_get}}
    end
  end
end
