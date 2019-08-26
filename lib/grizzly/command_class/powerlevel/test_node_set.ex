defmodule Grizzly.CommandClass.Powerlevel.TestNodeSet do
  @moduledoc """

  Command module for working with the Powerlevel command class TEST_NODE_SET command.
  It is used to temporarily decrease the RF transmit power level of a device while sending test frames to another.
   Command Options:
    * `:power_level` - By how much to decrease the RF transmit power level (:normal_power is no decrease): :normal_power | :minus1dBm | :minus2dBm | :minus3dBm | :minus4dBm | :minus5dBm | :minus6dBm | :minus7dBm | :minus8dBm | :minus9dBm
    * `:test_node_id` - The device to send frames to from this device
    * `:test_frame_count` - How many frames to send
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)

  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.Powerlevel

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          test_node_id: non_neg_integer(),
          power_level: Powerlevel.power_level_description(),
          test_frame_count: non_neg_integer
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:test_node_id, non_neg_integer()}
          | {:power_level, Powerlevel.power_level_description()}
          | {:test_frame_count, non_neg_integer()}

  @enforce_keys [:test_node_id, :power_level, :test_frame_count]

  defstruct seq_number: nil,
            retries: 2,
            test_node_id: nil,
            power_level: nil,
            test_frame_count: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{
        seq_number: seq_number,
        test_node_id: test_node_id,
        power_level: power_level,
        test_frame_count: test_frame_count
      }) do
    binary =
      Packet.header(seq_number) <>
        <<0x73, 0x04, test_node_id::size(8), Powerlevel.encode_power_level(power_level),
          test_frame_count::size(16)>>

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, Powerlevel.test_node_report()}
          | {:retry, t}
  def handle_response(%__MODULE__{seq_number: seq_number} = _command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: 0}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: n} = command, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _,
        %Packet{body: %{command_class: :powerlevel, command: :test_node_report, value: value}}
      ) do
    {:done, {:ok, value}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response, :nack_waiting]
        } = packet
      ) do
    if Packet.sleeping_delay?(packet) do
      {:queued, command}
    else
      {:continue, command}
    end
  end

  def handle_response(command, _), do: {:continue, command}
end
