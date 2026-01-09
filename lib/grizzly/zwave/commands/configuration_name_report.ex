defmodule Grizzly.ZWave.Commands.ConfigurationNameReport do
  @moduledoc """
   This command is used to advertise the name of a configuration parameter.

  Params:

    * `:param_number` -  This field is used to specify which configuration parameter (required)

    * `:name` -  This field is used to specify the name of the configuration parameter (required)

    * `reports_to_follow` - This field is used to specify the number of reports to follow (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param :: {:param_number, byte} | {:name, binary} | {:reports_to_follow, byte}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    name = Command.param!(command, :name)
    reports_to_follow = Command.param(command, :reports_to_follow, 0)
    <<param_number::16, reports_to_follow, name::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<param_number::16, reports_to_follow, name::binary>>) do
    {:ok, [param_number: param_number, reports_to_follow: reports_to_follow, name: name]}
  end
end
