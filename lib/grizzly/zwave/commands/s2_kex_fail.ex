defmodule Grizzly.ZWave.Commands.S2KexFail do
  @moduledoc """
  This command is used to advertise an error condition to the other party of an
  S2 bootstrapping process.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.Security

  @type param :: {:kex_fail_type, Security.key_exchange_fail_type()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_kex_fail,
      command_byte: 0x07,
      command_class: Security2,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    kex_fail_type = Command.param!(command, :kex_fail_type)

    <<Security.failed_type_to_byte(kex_fail_type)::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<kex_fail_type::8>>) do
    kex_fail_type = Security.failed_type_from_byte(kex_fail_type)

    {:ok, [kex_fail_type: kex_fail_type]}
  end
end
