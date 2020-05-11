defmodule Grizzly.ZWave do
  @moduledoc """
  Module for Z-Wave protocol specific functionality and information
  """

  alias Grizzly.ZWave.{Decoder, DecodeError, Command}

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()

  @spec from_binary(binary()) :: {:ok, Command.t()} | {:error, DecodeError.t()}
  def from_binary(binary) do
    Decoder.from_binary(binary)
  end

  @spec to_binary(Command.t()) :: binary()
  def to_binary(command) do
    Command.to_binary(command)
  end
end
