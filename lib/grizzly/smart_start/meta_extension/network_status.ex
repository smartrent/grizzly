defmodule Grizzly.SmartStart.MetaExtension.NetworkStatus do
  @moduledoc """
  This extension is used to advertise if the node is in the network and its
  assigned node id
  """
  alias Grizzly.Node

  @typedoc """
  The different network statuses are:

  - `:not_in_network` - the node in the provisioning list is not included in
    the network
  - `:included` - the node in the provisioning list is included in the network
    and is functional
  - `:failing` - the node in the provisioning list is included in the network
    but is now marked as failing
  """
  @type network_status :: :not_in_network | :included | :failing

  @type t :: %__MODULE__{
          node_id: Node.node_id(),
          network_status: network_status()
        }

  @enforce_keys [:node_id, :network_status]
  defstruct node_id: nil, network_status: nil

  @doc """
  Create a `NetworkStatus.t()`

  If the node is not included into the network the `node_id` has to be equal to
  `0`. If the node has been included into the network and is either functional
  or failing then it has to have a `node_id` greater than `0`.
  """
  @spec new(Node.node_id(), network_status()) ::
          {:ok, t()} | {:error, :invalid_network_status | :invalid_node_id}
  def new(node_id, :not_in_network) when node_id > 0 do
    {:error, :invalid_node_id}
  end

  def new(node_id, network_status)
      when node_id == 0 and network_status in [:included, :failing] do
    {:error, :invalid_node_id}
  end

  def new(node_id, network_status)
      when network_status in [:not_in_network, :included, :failing] do
    {:ok, %__MODULE__{node_id: node_id, network_status: network_status}}
  end

  def new(_, _) do
    {:error, :invalid_network_status}
  end

  @doc """
  Make a binary string from a `NetworkStatus.t()`
  """
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{node_id: node_id, network_status: network_status}) do
    {:ok, <<0x37::size(7), 0::size(1), 0x02, node_id, network_status_to_byte(network_status)>>}
  end

  @doc """
  Make a `NetworkStatus.t()` from a binary string

  The binary string's critical bit MUST not be set. If it is this function will
  return `{:error, :critical_bit_set}`
  """
  @spec from_binary(binary()) ::
          {:ok, t()} | {:error, :invalid_network_status | :critical_bit_set}
  def from_binary(<<0x37::size(7), 0::size(1), 0x02, node_id, network_status_byte>>) do
    case network_status_from_byte(network_status_byte) do
      {:ok, network_status} ->
        new(node_id, network_status)

      error ->
        error
    end
  end

  def from_binary(<<0x37::size(7), 1::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  defp network_status_to_byte(:not_in_network), do: 0x00
  defp network_status_to_byte(:included), do: 0x01
  defp network_status_to_byte(:failing), do: 0x02

  defp network_status_from_byte(0x00), do: {:ok, :not_in_network}
  defp network_status_from_byte(0x01), do: {:ok, :included}
  defp network_status_from_byte(0x02), do: {:ok, :failing}
  defp network_status_from_byte(_), do: {:error, :invalid_network_status}
end
