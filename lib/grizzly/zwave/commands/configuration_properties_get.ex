defmodule Grizzly.ZWave.Commands.ConfigurationPropertiesGet do
  @moduledoc """
  This command is used to request the properties of a configuration parameter.

  Params:

    * `:param_number` - This field is used to specify which configuration parameter (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param :: {:param_number, non_neg_integer}

  @impl true
  def new(params) do
    command = %Command{
      name: :configuration_properties_get,
      command_byte: 0x0E,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    <<param_number::size(16)>>
  end

  @impl true
  def decode_params(<<param_number::size(16)>>) do
    {:ok, [param_number: param_number]}
  end
end
