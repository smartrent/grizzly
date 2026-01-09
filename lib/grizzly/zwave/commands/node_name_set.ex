defmodule Grizzly.ZWave.Commands.NodeNameSet do
  @moduledoc """
  This command is used to set the name of the receiving node.

  Params:

    * `:encoding` - one of :ascii, :extended_ascii, :utf_16
    * `:name` - a string name for the node
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NodeNaming
  alias Grizzly.ZWave.DecodeError

  @type param :: {:name, String.t()} | {:encoding, :ascii | :extended_ascii | :utf_16}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    encoding = Command.param!(command, :encoding)
    name = Command.param!(command, :name)
    encoding_byte = NodeNaming.encoding_to_byte(encoding)
    <<0x00::5, encoding_byte::3>> <> name
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::5, encoding_byte::3, name::binary>>) do
    with {:ok, encoding} <- NodeNaming.encoding_from_byte(encoding_byte) do
      {:ok, [encoding: encoding, name: name]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
