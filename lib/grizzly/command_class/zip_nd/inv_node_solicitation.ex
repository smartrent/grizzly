defmodule Grizzly.CommandClass.ZipNd.InvNodeSolicitation do
  @behaviour Grizzly.Command

  alias Grizzly.{Node, Packet}
  alias Grizzly.Network.State, as: NetworkState

  @type t :: %__MODULE__{
          node_id: Node.node_id(),
          pre_states: [NetworkState.state()]
        }

  @type opt :: {:node_id, Node.node_id()} | {:pre_states, [NetworkState.state()]}

  defstruct node_id: nil,
            pre_states: [:not_ready, :idle]

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{node_id: node_id}) do
    {:ok, <<0x58, 0x04, 0x00, node_id>>}
  end

  @spec handle_response(t, Packet.t()) ::
          {:done, {:ok, {:node_ip, Node.node_id(), :inet.ip_address()}}}
  def handle_response(
        _,
        %Packet{
          body: %{command_class: :zip_nd, command: :zip_node_advertisement} = advertisement
        }
      ) do
    {:done, {:ok, {:node_ip, advertisement.node_id, advertisement.ip_address}}}
  end

  def handle_response(command, _), do: {:continue, command}
end
