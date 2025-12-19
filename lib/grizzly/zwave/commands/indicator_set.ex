defmodule Grizzly.ZWave.Commands.IndicatorSet do
  @moduledoc """
  This command is used to manipulate one or more indicator resources at a supporting node.

  Params:

    * `:value` - This field is used to enable or disable the indicator resource (required if v1 - optional and ignored otherwise)

    * `:resources` - Indicator objects, each with an indicator id, property id and value (optional, v2+)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Indicator
  alias Grizzly.ZWave.DecodeError

  @type param :: {:value, Indicator.value()} | {:resource, [Indicator.resource()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_set,
      command_byte: 0x01,
      command_class: Indicator,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    value = Command.param(command, :value)

    if value != nil do
      <<value>>
    else
      resources = Command.param!(command, :resources)

      resources_binary =
        for resource <- resources, into: <<>> do
          indicator_id_byte =
            Keyword.fetch!(resource, :indicator_id) |> Indicator.indicator_id_to_byte()

          property_id = Keyword.fetch!(resource, :property_id)
          property_id_byte = Indicator.property_id_to_byte(property_id)
          value = Keyword.fetch!(resource, :value) |> Indicator.value_to_byte(property_id)

          <<indicator_id_byte, property_id_byte, value>>
        end

      count = Enum.count(resources)
      <<0x00, 0x00::3, count::5>> <> resources_binary
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<value>>) do
    {:ok, [value: value]}
  end

  def decode_params(<<_ignored, 0x00::3, _count::5, resources_binary::binary>>) do
    :binary.bin_to_list(resources_binary)
    |> Enum.chunk_every(3)
    |> Enum.reduce_while(
      {:ok, [resources: []]},
      fn [indicator_id_byte, property_id_byte, value], {:ok, [resources: acc]} ->
        with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte),
             {:ok, property_id} <- Indicator.property_id_from_byte(property_id_byte),
             {:ok, decoded_value} <- Indicator.value_from_byte(value, property_id) do
          {:cont,
           {:ok,
            [
              resources: [
                [indicator_id: indicator_id, property_id: property_id, value: decoded_value] | acc
              ]
            ]}}
        else
          {:error, %DecodeError{} = decode_error} ->
            {:halt, {:error, %DecodeError{decode_error | command: :indicator_set}}}
        end
      end
    )
  end
end
