defmodule Grizzly.ZWave.Commands.MultiChannelCommandEncapsulation do
  @moduledoc """
  This command is used to encapsulate commands to or from a Multi Channel End Point.

  Params:

    * `:source_end_point` - the originating End Point (defaults to 0 - if 0, destination_end_point must be non-zero).

    * `:bit_address?` - whether the End Point is bit-masked, or as-is (defaults to false)

    * `:destination_end_point` - the destination End Point. (defaults to 0 - - if 0, source_end_point must be non-zero)

    * `:command_class` - the command class of the command sent (required)

    * `:command` - the name of the command (required)

    * `:parameters` - the command parameters (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.Commands.Table
  alias Grizzly.ZWave.{Command, CommandClasses, DecodeError, Decoder}
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param ::
          {:source_end_point, MultiChannel.end_point()}
          | {:destination_end_point, MultiChannel.end_point()}
          | {:bit_address?, boolean()}
          | {:command_class, CommandClasses.command_class()}
          | {:command, atom()}
          | {:parameters, Command.params()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_command_encapsulation,
      command_byte: 0x0D,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    source_end_point = Command.param(command, :source_end_point, 0)
    destination_end_point = Command.param(command, :destination_end_point, 0)
    bit_address? = Command.param(command, :bit_address?, false)
    command_class = Command.param!(command, :command_class)
    encapsulated_command_name = Command.param!(command, :command)
    parameters = Command.param!(command, :parameters)
    destination_end_point_byte = encode_destination_end_point(destination_end_point, bit_address?)
    encoded_command_class = CommandClasses.to_byte(command_class)
    encapsulated_command = make_command(encapsulated_command_name, parameters)
    encapsulated_parameters = encapsulated_command.impl.encode_params(encapsulated_command)
    encapsulated_command_byte = encapsulated_command.command_byte

    if encapsulated_command_byte == nil do
      # The no_operation command has no command byte
      <<0x00::1, source_end_point::7, destination_end_point_byte, encoded_command_class>>
    else
      <<0x00::1, source_end_point::7, destination_end_point_byte, encoded_command_class,
        encapsulated_command_byte>>
    end <>
      encapsulated_parameters
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<0x00::1, source_end_point::7, bit_address::1, encoded_destination_end_point::7,
          command_class_byte, command_byte, parameters_binary::binary>>
      ) do
    {:ok, command_class} = CommandClasses.from_byte(command_class_byte)
    bit_address? = bit_address == 1

    destination_end_point =
      decode_destination_end_point(encoded_destination_end_point, bit_address?)

    with {:ok, encapsulated_command} <-
           decode_command(command_class_byte, command_byte, parameters_binary) do
      decoded_params = [
        source_end_point: source_end_point,
        bit_address?: bit_address?,
        destination_end_point: destination_end_point,
        command_class: command_class,
        command: encapsulated_command.name,
        parameters: encapsulated_command.params
      ]

      {:ok, decoded_params}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_destination_end_point(0, _bit_address?), do: 0

  defp encode_destination_end_point(destination_end_point, false)
       when destination_end_point in 1..127,
       do: destination_end_point

  defp encode_destination_end_point(destination_end_point, true)
       when destination_end_point in 1..7 do
    <<byte>> =
      for i <- 7..1//-1, into: <<0x01::1>> do
        if destination_end_point == i, do: <<0x01::1>>, else: <<0x00::1>>
      end

    byte
  end

  defp make_command(command_name, parameters) do
    {command_module, _} = Table.lookup(command_name)

    {:ok, command} = command_module.new(parameters)
    command
  end

  defp decode_command(command_class_byte, command_byte, parameters_binary) do
    Decoder.from_binary(<<command_class_byte, command_byte>> <> parameters_binary)
  end

  defp decode_destination_end_point(0, _bit_address?), do: 0
  defp decode_destination_end_point(destination_end_point, false), do: destination_end_point

  defp decode_destination_end_point(encoded_destination_end_point, true) do
    bit_index =
      for(<<(x::1 <- <<encoded_destination_end_point>>)>>, do: x)
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.find(fn {bit, _index} ->
        bit == 1
      end)
      |> elem(1)

    bit_index + 1
  end
end
