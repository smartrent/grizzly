defmodule Grizzly.ZWave.Commands.NodeNameSet do
  @moduledoc """
  This command is used to set the name of the receiving node.

  Params:

    * `:encoding` - one of :ascii, :extended_ascii, :utf_16
    * `:name` - a string name for the node
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NodeNaming

  @type param :: {:name, String.t()} | {:encoding, :ascii | :extended_ascii | :utf_16}

  @impl true
  def new(params) do
    command = %Command{
      name: :node_name_set,
      command_byte: 0x01,
      command_class: NodeNaming,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    encoding = Command.param!(command, :encoding)
    name = Command.param!(command, :name)
    encoding_byte = NodeNaming.encoding_to_byte(encoding)
    <<0x00::size(5), encoding_byte::size(3)>> <> name
  end

  @impl true
  def decode_params(<<_reserved::size(5), encoding_byte::size(3), name::binary>>) do
    with {:ok, encoding} <- NodeNaming.encoding_from_byte(encoding_byte) do
      {:ok, [encoding: encoding, name: name]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end
end
