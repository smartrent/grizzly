defmodule Grizzly.ZWave.Commands.NodeNameSet do
  @moduledoc """
  This command is used to set the name of the receiving node.

  Params:

    * `:encoding` - one of :ascii, :extended_ascii, :utf_16
    * `:name` - a string name for the node
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command

  @type param :: {:name, String.t()} | {:encoding, :ascii | :extended_ascii | :utf_16}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    encoding = Command.param!(command, :encoding)
    name = Command.param!(command, :name)
    encoding_byte = encode_string_encoding(encoding)
    <<0x00::5, encoding_byte::3>> <> name
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::5, encoding_byte::3, name::binary>>) do
    {:ok, [encoding: decode_string_encoding(encoding_byte), name: name]}
  end
end
