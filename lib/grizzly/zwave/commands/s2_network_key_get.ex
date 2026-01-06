defmodule Grizzly.ZWave.Commands.S2NetworkKeyGet do
  @moduledoc """
  This command is used by a joining node to request one key from the including
  node. One instance of this command MUST be sent for each key that was granted
  by the including node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.Security

  @type param :: {:requested_key, Security.key()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_network_key_get,
      command_byte: 0x09,
      command_class: Security2,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    requested_key = Command.param!(command, :requested_key)

    <<Security.key_to_byte(requested_key)::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<requested_key::8>>) do
    requested_key = Security.key_from_byte(requested_key)

    {:ok, [requested_key: requested_key]}
  end
end
