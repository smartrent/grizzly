defmodule Grizzly.ZWave.Commands.ConfigurationPropertiesGet do
  @moduledoc """
  This command is used to request the properties of a configuration parameter.

  Params:

    * `:param_number` - This field is used to specify which configuration parameter (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:param_number, non_neg_integer}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    <<param_number::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<param_number::16>>) do
    {:ok, [param_number: param_number]}
  end
end
