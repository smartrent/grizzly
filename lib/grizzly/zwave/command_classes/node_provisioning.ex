defmodule Grizzly.ZWave.CommandClasses.NodeProvisioning do
  @moduledoc """
  NodeProvisioning Command Class

  The Node Provisioning command class is used to manage a list of unique nodes,
  called the "Node Provisioning List", in SmartStart controller or gateway.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.SmartStart.MetaExtension
  alias Grizzly.ZWave.DSK

  @impl true
  def byte(), do: 0x78

  @impl true
  def name(), do: :node_provisioning

  def encode_meta_extensions(meta_extensions),
    do:
      Enum.reduce(meta_extensions, <<>>, fn extension, extensions_bin ->
        extensions_bin <> MetaExtension.encode(extension)
      end)

  @doc """
  Get the binary representation of the dsk

  If the DSK is `nil` then this will return an empty binary.
  """
  @spec optional_dsk_to_binary(DSK.t() | nil) :: binary()
  def optional_dsk_to_binary(nil) do
    <<>>
  end

  def optional_dsk_to_binary(dsk) do
    dsk.raw
  end

  @doc """
  Get the DSK from a raw binary

  If the binary is empty this will return `{:ok, nil}`.
  """
  @spec optional_binary_to_dsk(binary()) :: DSK.t() | nil
  def optional_binary_to_dsk(<<>>) do
    nil
  end

  def optional_binary_to_dsk(binary) do
    DSK.new(binary)
  end
end
