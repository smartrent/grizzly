defmodule Grizzly.ZWave.Commands.AdminPinCodeGet do
  @moduledoc """
  AdminPinCodeGet is used to request the admin code currently set at the receiving node.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :admin_pin_code_get,
      command_byte: 0x1B,
      command_class: UserCredential,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [keyword()]} | {:error, DecodeError.t()}
  def decode_params(_binary) do
    {:ok, []}
  end
end
