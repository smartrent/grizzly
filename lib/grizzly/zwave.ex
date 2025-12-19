defmodule Grizzly.ZWave do
  @moduledoc """
  Module for Z-Wave protocol specific functionality and information
  """

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.DecodeError

  @type seq_number :: non_neg_integer()

  @type node_id :: non_neg_integer()
  @type endpoint_id :: 0..127

  @spec from_binary(binary()) :: {:ok, Command.t()} | {:error, DecodeError.t()}
  def from_binary(binary) do
    Logger.metadata(zwave_command: inspect(binary, base: :hex, limit: 100))

    Commands.decode(binary)
  end

  @spec to_binary(Command.t()) :: binary()
  def to_binary(command) do
    Command.to_binary(command)
  end
end
