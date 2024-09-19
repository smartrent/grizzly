defmodule Grizzly.ZWave.Commands.IndicatorReport do
  @moduledoc """
  This command is used to advertise the state of an indicator resource.

  Params:

    * `:indicator_id` - This field is used to specify the actual indicator resource (required for v2+)
    * `:value` - Value of the implied property 0x01 of implied indicator resource 0x00. It is added to :resources
                 if the resources field would otherwise be empty. Else ignored. (required v1)
    * `:resources` - Indicator resources (required for v2+ only)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Indicator

  @type param :: {:resources, [Indicator.resource()]} | {:value, byte}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :indicator_report,
      command_byte: 0x03,
      command_class: Indicator,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    resources = Command.param(command, :resources)

    if resources == nil do
      value = Command.param!(command, :value)
      <<value>>
    else
      if Enum.empty?(resources) do
        <<0x00, 0x00::3, 0x00::5>>
      else
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
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<value>>) do
    {:ok, [value: value, resources: [[indicator_id: 0x00, property_id: 0x01, value: value]]]}
  end

  def decode_params(<<value0, 0x00::3, _count::5, resources_binary::binary>>) do
    result =
      :binary.bin_to_list(resources_binary)
      |> Enum.chunk_every(3)
      |> Enum.reduce_while(
        {:ok, []},
        fn [indicator_id_byte, property_id_byte, property_value], {:ok, acc} ->
          with {:ok, indicator_id} <- Indicator.indicator_id_from_byte(indicator_id_byte),
               {:ok, property_id} <- Indicator.property_id_from_byte(property_id_byte),
               {:ok, decoded_value} <- Indicator.value_from_byte(property_value, property_id) do
            {:cont,
             {:ok,
              [
                [indicator_id: indicator_id, property_id: property_id, value: decoded_value] | acc
              ]}}
          else
            {:error, %DecodeError{} = decode_error} ->
              {:halt, {:error, %DecodeError{decode_error | command: :indicator_set}}}
          end
        end
      )

    case result do
      {:ok, resources} ->
        if Enum.empty?(resources) do
          # the value is implicitly that of Indicator ID 0 = 0x00, Property ID 0 = 0x01
          {:ok,
           [value: value0, resources: [indicator_id: 0x00, property_id: 0x01, value: value0]]}
        else
          # Controller must ignore the value if there are resources
          {:ok, [value: 0x00, resources: resources]}
        end

      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
