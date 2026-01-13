defmodule Grizzly.ZWave.Commands.ConfigurationInfoReport do
  @moduledoc """
   This command is used to advertise the documentation for a configuration parameter.

  Params:

    * `:param_number` -  This field is used to specify which configuration parameter (required)

    * `:info` -  This field is used to specify the documentation for the configuration parameter (required)

    * `reports_to_follow` - This field is used to specify the number of reports to follow (optional)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:param_number, byte} | {:info, binary} | {:reports_to_follow, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    param_number = Command.param!(command, :param_number)
    info = Command.param!(command, :info)
    reports_to_follow = Command.param(command, :reports_to_follow, 0)
    <<param_number::16, reports_to_follow, info::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<param_number::16, reports_to_follow, info::binary>>) do
    {:ok, [param_number: param_number, reports_to_follow: reports_to_follow, info: info]}
  end
end
