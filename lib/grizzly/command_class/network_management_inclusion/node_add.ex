defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAdd do
  @moduledoc """
  Module for using the NODE_ADD command.

  If the inclusion process is for S0 or no security the process will
  add the node and do the security (if S0) exchange at the `zipgateway`
  level.

  If the inclusion process is for S2 security, there will be a
  node add keys report, which is to request granting what level
  of S2 security the user ought to grant. This request will let
  the caller know if Client Side Authentication is request and what
  S2 keys to grant to the joining node.
  """
  @behaviour Grizzly.Command

  alias Grizzly.{Node, Packet, Security}
  alias Grizzly.Network.State, as: NetworkState
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.NetworkManagementInclusion

  @typedoc """
  Mode for the controller to use during inclusion

  - `:any` - add any type of node to the network and allow for S0 bootstrapping
  - `:stop` - stop add mode
  - `:any_s2` - same as `:any`, but allow for S2 bootstrapping as well (v2)
  """

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          tx_opts: byte,
          mode: NetworkManagementInclusion.add_mode() | byte,
          pre_states: [NetworkState.state()],
          exec_state: NetworkState.state(),
          timeout: non_neg_integer
        }

  defstruct mode: :any_s2,
            tx_opts: 0x20,
            seq_number: nil,
            pre_states: nil,
            exec_state: nil,
            timeout: nil

  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number, tx_opts: tx_opts} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             mode: {:encode_with, NetworkManagementInclusion, :encode_add_mode}
           }) do
      binary =
        Packet.header(seq_number) <> <<0x34, 0x01, seq_number, 0x00, encoded.mode, tx_opts>>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, Node.t()}
          | {:done, {:ok, :node_add_stopped}}
  def handle_response(
        %__MODULE__{seq_number: seq_number, mode: :stop},
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, {:ok, :node_add_stopped}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:continue, command}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number},
        %Packet{
          seq_number: seq_number,
          body: %{
            command: :node_add_status,
            status: :failed
          }
        }
      ) do
    {:done, {:error, :node_add_failed}}
  end

  def handle_response(_, %Packet{body: %{command: :node_add_status, status: status} = report})
      when status in [:done, :security_failed] do
    zw_node =
      Node.new(
        id: report.node_id,
        command_classes: report.command_classes,
        security: security_from_report(status, report.keys_granted),
        basic_cmd_class: report.basic_class,
        generic_cmd_class: report.generic_class,
        specific_cmd_class: report.specific_class,
        listening?: report.listening?
      )

    {:done, {:ok, zw_node}}
  end

  def handle_response(
        command,
        %Packet{
          body: %{
            command: :node_add_keys_report,
            csa?: csa?,
            requested_keys: requested_keys
          }
        }
      ) do
    {
      :send_message,
      {:node_add_keys_report, %{csa?: csa?, requested_keys: requested_keys}},
      command
    }
  end

  def handle_response(command, _), do: {:continue, command}

  defp security_from_report(:security_failed, _), do: :failed

  defp security_from_report(:done, keys_granted) do
    Security.get_highest_level(keys_granted)
  end
end
