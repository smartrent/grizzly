defmodule Grizzly.ZWave.Commands.CRC16Encap do
  @moduledoc """
  The CRC-16 Encapsulation Command is used to encapsulate a command with an additional checksum to
  ensure integrity of the payload.

  Params:

    * `:command` - the encapsulated Command

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CRC
  alias Grizzly.ZWave.DecodeError

  @type param :: {:command, Command.t()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command = Command.param!(command, :command)
    command_binary = Grizzly.ZWave.to_binary(command)
    checksum = CRC.crc16_aug_ccitt(command_binary)
    command_binary <> <<checksum::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<command_class_byte, command_byte, data_and_checksum::binary>> = binary
      ) do
    with {:ok, encoded_params, checksum} <- extract_params_and_checksum(data_and_checksum),
         command_binary = <<command_class_byte, command_byte>> <> encoded_params,
         ^checksum <- CRC.crc16_aug_ccitt(command_binary),
         {:ok, command} <- Grizzly.ZWave.from_binary(command_binary) do
      {:ok, [command: command]}
    else
      _other ->
        {:error, %DecodeError{value: binary, param: :command, command: :crc_16_encap}}
    end
  end

  defp extract_params_and_checksum(data_and_checksum) do
    case :erlang.binary_to_list(data_and_checksum) |> Enum.reverse() do
      [checksum_2, checksum_1 | reversed_param_bytes] ->
        checksum_binary = <<checksum_1, checksum_2>>
        <<checksum::16>> = checksum_binary
        encoded_params = :erlang.list_to_binary(Enum.reverse(reversed_param_bytes))
        {:ok, encoded_params, checksum}

      _other ->
        {:error, :invalid}
    end
  end
end
