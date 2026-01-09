defmodule Grizzly.ZWave.Commands.NodeLocationReport do
  @moduledoc """
  This command is used to advertize the location of the receiving node.

  Params:

    * `:encoding` - one of :ascii, :extended_ascii, :utf_16

    * `:location` - a string location for the node

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command

  @type param :: {:location, String.t()} | {:encoding, :ascii | :extended_ascii | :utf_16}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    encoding = Command.param!(command, :encoding)
    location = Command.param!(command, :location)
    encoding_byte = encode_string_encoding(encoding)
    <<0x00::5, encoding_byte::3>> <> location
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::5, encoding_byte::3, location::binary>>) do
    {:ok, [encoding: decode_string_encoding(encoding_byte), location: location]}
  end
end
