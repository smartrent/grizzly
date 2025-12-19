defmodule Grizzly.ZWave.Commands.Hail do
  @moduledoc """
  Send an unsolicited Hail command to other devices on the network

  Params: None
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Hail
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :hail,
      command_byte: 0x01,
      command_class: Hail,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
