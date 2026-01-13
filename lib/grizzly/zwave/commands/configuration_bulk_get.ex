defmodule Grizzly.ZWave.Commands.ConfigurationBulkGet do
  @moduledoc """
  This command is used to query the value of one or more configuration parameters.

  Params:

    * `:offset` - This field is used to specify the first parameter in a range of one or more parameters. (required)

    * `:number_of_parameters` - This field is used to specify the number of requested configuration parameters.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:number_of_parameters, non_neg_integer} | {:offset, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    number_of_parameters = Command.param!(command, :number_of_parameters)
    offset = Command.param!(command, :offset)
    <<offset::16, number_of_parameters>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<offset::16, number_of_parameters>>) do
    {:ok, [number_of_parameters: number_of_parameters, offset: offset]}
  end
end
