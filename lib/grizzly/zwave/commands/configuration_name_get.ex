defmodule Grizzly.ZWave.Commands.ConfigurationNameGet do
  @moduledoc """
  This command is used to get the name of a configuration parameter.

  Params:

    * `:param_number` - the requested configuration parameter

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param :: {:param_number, byte}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :configuration_name_get,
      command_byte: 0x0A,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    <<param_number::size(16)>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<param_number::size(16)>>) do
    {:ok, [param_number: param_number]}
  end
end
