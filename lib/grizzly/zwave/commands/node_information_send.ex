defmodule Grizzly.ZWave.Commands.NodeInformationSend do
  @moduledoc """
  Instruct a node to send its Node Information Frame to another node (typically
  a controller).

  ### Params

  * seq_number - the sequence number of the network managment command (required)
  * destination_node_id - the node that should receive the node information frame (required)
  * tx_options - the transmission options for the target node to use when sending its NIF (optional)
  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @type tx_opt :: :ack | :low_power | :no_route | :explore

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:destination_node_id, Grizzly.node_id()}
          | {:tx_options, [tx_opt()]}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :node_information_send,
      command_byte: 0x05,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    destination_node_id = Command.param!(command, :destination_node_id)
    tx_options = Command.param(command, :tx_options, []) |> encode_tx_options()

    <<seq_number::8, 0::8, destination_node_id::8, tx_options::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number::8, _reserved::8, destination_node_id::8, tx_options::8>>) do
    {:ok,
     [
       seq_number: seq_number,
       destination_node_id: destination_node_id,
       tx_options: decode_tx_options(tx_options)
     ]}
  end

  @spec encode_tx_options([tx_opt()]) :: byte()
  defp encode_tx_options(tx_options) do
    Enum.reduce(tx_options, 0, fn tx_option, acc ->
      acc ||| tx_opt_to_byte(tx_option)
    end)
  end

  @spec decode_tx_options(byte()) :: [tx_opt()]
  defp decode_tx_options(tx_options) do
    [
      if((tx_options &&& 0x01) == 0x01, do: :ack),
      if((tx_options &&& 0x02) == 0x02, do: :low_power),
      if((tx_options &&& 0x10) == 0x10, do: :no_route),
      if((tx_options &&& 0x20) == 0x20, do: :explore)
    ]
    |> Enum.filter(& &1)
  end

  @spec tx_opt_to_byte(tx_opt()) :: byte()
  defp tx_opt_to_byte(:ack), do: 0x01
  defp tx_opt_to_byte(:low_power), do: 0x02
  defp tx_opt_to_byte(:no_route), do: 0x10
  defp tx_opt_to_byte(:explore), do: 0x20
end
