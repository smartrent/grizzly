defmodule Grizzly.ZWave.Commands.ConfigurationNameGet do
  @moduledoc """
  This command is used to get the name of a configuration parameter.

  Params:

    * `:param_number` - the requested configuration parameter

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:param_number, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    param_number = Command.param!(command, :param_number)
    <<param_number::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<param_number::16>>) do
    {:ok, [param_number: param_number]}
  end
end
