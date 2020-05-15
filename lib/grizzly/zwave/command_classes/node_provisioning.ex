defmodule Grizzly.ZWave.CommandClasses.NodeProvisioning do
  @moduledoc """
  NodeProvisioning Command Class

  The Node Provisioning command class is used to manage a list of unique nodes,
  called the "Node Provisioning List", in SmartStart controller or gateway.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.SmartStart.MetaExtension

  @impl true
  def byte(), do: 0x78

  @impl true
  def name(), do: :node_provisioning

  def encode_meta_extensions(meta_extensions),
    do:
      Enum.reduce(meta_extensions, <<>>, fn extension, extensions_bin ->
        extensions_bin <> MetaExtension.extension_to_binary(extension)
      end)
end
