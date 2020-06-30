defmodule Grizzly.ZWave.Commands.ApplicationNodeInfoGet do
  @moduledoc """
  Get the node information frame of for the Z/IP Gateway controller

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZIPGateway

  @impl true
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :application_node_info_get,
      command_byte: 0x0C,
      command_class: ZIPGateway,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
