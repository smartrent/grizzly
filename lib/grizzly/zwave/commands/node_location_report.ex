defmodule Grizzly.ZWave.Commands.NodeLocationReport do
  @moduledoc """
  This command is used to advertize the location of the receiving node.

  Params:

    * `:encoding` - one of :ascii, :extended_ascii, :utf_16

    * `:location` - a string location for the node

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NodeNaming

  @type param :: {:location, String.t()} | {:encoding, :ascii | :extended_ascii | :utf_16}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :node_location_report,
      command_byte: 0x06,
      command_class: NodeNaming,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    encoding = Command.param!(command, :encoding)
    location = Command.param!(command, :location)
    encoding_byte = NodeNaming.encoding_to_byte(encoding)
    <<0x00::5, encoding_byte::3>> <> location
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::5, encoding_byte::3, location::binary>>) do
    with {:ok, encoding} <- NodeNaming.encoding_from_byte(encoding_byte) do
      {:ok, [encoding: encoding, location: location]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
