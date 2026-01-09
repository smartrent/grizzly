defmodule Grizzly.ZWave.Commands.WindowCoveringSupportedReport do
  @moduledoc """
  This command is used to advertise the supported properties of a windows covering device.

  Params:

    * `:parameter_names` - names of parameters supported by the device

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.WindowCovering
  alias Grizzly.ZWave.DecodeError

  @type param :: {:parameter_names, [WindowCovering.parameter_name()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    parameter_names = Command.param!(command, :parameter_names)

    parameter_ids =
      for parameter_name <- parameter_names,
          do: WindowCovering.encode_parameter_name(parameter_name)

    parameter_masks_binary = parameter_ids_to_bitmasks(parameter_ids)
    <<0x00::4, byte_size(parameter_masks_binary)::size(4)>> <> parameter_masks_binary
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<_reserved::4, number_of_parameter_masks::4, parameter_masks::binary>>) do
    case bitmasks_to_parameter_names(parameter_masks, number_of_parameter_masks) do
      {:ok, parameter_names} ->
        {:ok, [parameter_names: parameter_names]}

      {:error, :invalid_masks} ->
        {:error,
         %DecodeError{
           value: parameter_masks,
           param: :parameter_ids,
           command: :window_covering_supported_report
         }}
    end
  end

  defp parameter_ids_to_bitmasks(parameter_ids) do
    bitmasks =
      for(id <- 1..Enum.max(parameter_ids), do: if(id in parameter_ids, do: 1, else: 0))
      |> Enum.chunk_every(8, 8, [0, 0, 0, 0, 0, 0, 0, 0])
      |> Enum.map(&for bit <- &1, into: <<>>, do: <<bit::1>>)

    for bitmask <- bitmasks, into: <<>>, do: bitmask
  end

  defp bitmasks_to_parameter_names(binary, number_of_parameter_masks) do
    parameter_masks = for <<mask::8 <- binary>>, do: <<mask::8>>

    bits =
      parameter_masks
      |> Enum.map(&for <<bit::1 <- &1>>, into: [], do: bit)
      |> List.flatten()

    if Enum.count(bits) == number_of_parameter_masks * 8 do
      parameter_ids = for id <- 1..Enum.count(bits), Enum.at(bits, id - 1) != 0, into: [], do: id

      Enum.reduce_while(parameter_ids, {:ok, []}, fn parameter_id, {:ok, acc} ->
        case WindowCovering.decode_parameter_name(parameter_id) do
          {:ok, parameter_name} ->
            {:cont, {:ok, [parameter_name | acc]}}

          {:error, %DecodeError{} = error} ->
            {:halt, {:error, error}}
        end
      end)
    else
      {:error, :invalid_masks}
    end
  end
end
