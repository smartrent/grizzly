defmodule Grizzly.ZWave.Commands.S2KexFail do
  @moduledoc """
  This command is used to advertise an error condition to the other party of an
  S2 bootstrapping process.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Security

  @type param :: {:kex_fail_type, Security.key_exchange_fail_type()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    kex_fail_type = Command.param!(command, :kex_fail_type)

    <<Security.failed_type_to_byte(kex_fail_type)::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<kex_fail_type::8>>) do
    kex_fail_type = Security.failed_type_from_byte(kex_fail_type)

    {:ok, [kex_fail_type: kex_fail_type]}
  end
end
