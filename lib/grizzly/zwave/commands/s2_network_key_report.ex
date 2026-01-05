defmodule Grizzly.ZWave.Commands.S2NetworkKeyReport do
  @moduledoc """
  This command is used by an including node to transfer one key to the joining
  node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.Security

  @type param :: {:granted_key, Security.key(), network_key: <<_::128>>}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_network_key_report,
      command_byte: 0x0A,
      command_class: Security2,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    granted_key = Command.param!(command, :granted_key)
    <<Security.key_to_byte(granted_key)::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<granted_key::8>>) do
    granted_key = Security.key_from_byte(granted_key)
    {:ok, [granted_key: granted_key]}
  end
end
