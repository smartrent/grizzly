defmodule Grizzly.ZWave.Commands.ConfigurationGet do
  @moduledoc """
  This command is used to query the value of a configuration parameter.

  Params:

    * `:param_number` - the requested configuration parameter

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param :: {:param_number, byte}

  @impl true
  def new(params) do
    command = %Command{
      name: :configuration_get,
      command_byte: 0x05,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    <<param_number>>
  end

  @impl true
  def decode_params(<<param_number>>) do
    {:ok, [param_number: param_number]}
  end
end
