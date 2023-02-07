defmodule Grizzly.ZWave.Commands.ExtendedUserCodeReport do
  @moduledoc """
  This command is used to report the user code of a specific user identifier.

  ## Params

  * `:user_codes` - A list of user codes. This field must respect the Z-Wave MAC
    frame or Transport service limits when sending this command, which typically
    means there should be no more than 8 user codes per command. It is up to
    the sender to ensure this limit is respected.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCode

  @type param ::
          {:user_codes, [UserCode.extended_user_code()]}
          | {:next_user_id, UserCode.extended_user_id()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :extended_user_code_report,
      command_byte: 0x0D,
      command_class: UserCode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    user_codes = Command.param!(command, :user_codes)
    next_user_id = Command.param(command, :next_user_id, 0) || 0

    user_codes_bin =
      for code <- user_codes, into: <<length(user_codes)::8>> do
        UserCode.encode_extended_user_code(code)
      end

    user_codes_bin <> <<next_user_id::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_user_codes_count::8, user_codes::binary>>) do
    case UserCode.decode_extended_user_codes(user_codes) do
      {codes, <<next_user_id::16>>} ->
        {:ok, [user_codes: codes, next_user_id: next_user_id]}

      # This case is technically not allowed by spec, but some locks omit the
      # next_user_id field when only reporting a single user code.
      {codes, <<>>} ->
        {:ok, [user_codes: codes, next_user_id: 0]}
    end
  end
end
