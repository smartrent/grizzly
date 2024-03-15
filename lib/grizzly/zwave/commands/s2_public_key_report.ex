defmodule Grizzly.ZWave.Commands.S2PublicKeyReport do
  @moduledoc """
  This command is used by both the including and the joining node to establish
  the Elliptic Curve Shared Secret. This is needed to establish the temporary
  secure channel that enables transfer of all other keys.
  """
  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2

  @type param :: {:ecdh_public_key, binary()} | {:including_node, boolean()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_public_key_report,
      command_byte: 0x08,
      command_class: Security2,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    including_node = Command.param!(command, :including_node)
    ecdh_public_key = Command.param!(command, :ecdh_public_key)

    <<0::7, bool_to_bit(including_node)::1>> <> ecdh_public_key
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::7, including_node::1, ecdh_public_key::binary>>) do
    including_node = bit_to_bool(including_node)

    {:ok, [including_node: including_node, ecdh_public_key: ecdh_public_key]}
  end
end
