defmodule Grizzly.ZWave.Commands.ExtendedUserCodeGet do
  @moduledoc """
  This command is used to request the user code of a specific user identifier.

  ## Params

  * `:user_id` - The user identifier to request the user code for.
  * `:report_more?` - This field is used to instruct the receiving node to report
    as many user codes as possible within a single Z-Wave command because the sending
    node intends to read the whole (or a large part of the) user code database.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:user_id, UserCode.extended_user_id()} | {:report_more?, boolean()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    user_id = Command.param!(command, :user_id)
    report_more? = Command.param(command, :report_more?, false)

    <<user_id::16, 0::7, bool_to_bit(report_more?)::1>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<user_id::16, _reserved::7, report_more?::1>>) do
    {:ok,
     [
       user_id: user_id,
       report_more?: bit_to_bool(report_more?)
     ]}
  end
end
