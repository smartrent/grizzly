defmodule Grizzly.ZWave do
  @moduledoc """
  Module for Z-Wave protocol specific functionality and information
  """

  alias Grizzly.ZWave.{Decoder, DecodeError, Command}
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()

  @spec from_binary(binary()) :: {:ok, Command.t() | ZIPPacket.t()} | {:error, DecodeError.t()}
  def from_binary(binary) do
    if is_keep_alive?(binary) do
      decode_keep_alive(binary)
    else
      decode_zip_packet(binary)
    end
  end

  defp is_keep_alive?(<<0x23, 0x03, _>>), do: true
  defp is_keep_alive?(_), do: false

  defp decode_keep_alive(binary) do
    case Decoder.from_binary(binary) do
      {:ok, _ka} = result -> result
    end
  end

  defp decode_zip_packet(binary) do
    case ZIPPacket.from_binary(binary) do
      {:ok, _zip_packet} = result -> result
    end
  end
end
