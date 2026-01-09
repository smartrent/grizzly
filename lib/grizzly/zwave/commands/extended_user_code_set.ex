defmodule Grizzly.ZWave.Commands.ExtendedUserCodeSet do
  @moduledoc """
  This command is used to request the user code of a specific user identifier.

  ## Params

  * `:user_codes` - A list of user codes to set. This field must respect the
    Z-Wave MAC frame or Transport service limits when sending this command, which
    typically means there should be no more than 10 user codes per command. It is
    up to the sender to ensure this limit is respected.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param :: {:user_codes, [UserCode.extended_user_code()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_codes = Command.param!(command, :user_codes)

    for code <- user_codes, into: <<length(user_codes)::8>> do
      UserCode.encode_extended_user_code(code)
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_user_codes_count::8, user_codes::binary>>) do
    {codes, _rest} = UserCode.decode_extended_user_codes(user_codes)

    {:ok,
     [
       user_codes: codes
     ]}
  end
end
