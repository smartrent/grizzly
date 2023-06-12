defmodule Grizzly.ZWave.Commands.MailboxConfigurationGet do
  @moduledoc """
  The Mailbox Configuration Get Command is used to request the Mailbox
  configuration from a supporting device.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @impl Grizzly.ZWave.Command
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_configuration_get,
      command_byte: 0x01,
      command_class: Mailbox,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
