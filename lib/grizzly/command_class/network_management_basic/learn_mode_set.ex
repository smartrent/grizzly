defmodule Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet do
  @moduledoc """
  Command module for working with the NetworkManagementBasic command class LEARN_MODE_SET command

  Command Options:

    * `:seq_number` - the sequence number used for the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
    * `:mode` - either :enable, :enable_routed, :disable (:enable = accept only being included in direct range - default mode)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Network.State, as: NetworkState

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          mode: mode(),
          pre_states: [NetworkState.state()],
          exec_state: NetworkState.state(),
          timeout: non_neg_integer
        }

  @type opt :: {:seq_number, Grizzly.seq_number()} | {:retries, non_neg_integer()}
  @type mode :: :enable | :disable

  defstruct seq_number: nil,
            retries: 2,
            # default
            mode: :enable,
            pre_states: nil,
            exec_state: nil,
            timeout: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  def encode(%__MODULE__{seq_number: seq_number, mode: mode}) do
    binary = Packet.header(seq_number) <> <<0x4D, 0x01, seq_number, 0x00, learn_mode(mode)>>
    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, :done | :busy}
          | {:retry, t}
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
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _command,
        %Packet{
          body: %{
            command: :learn_mode_set_status,
            report: report
          }
        }
      ) do
    {:done, {:ok, report}}
  end

  def handle_response(command, _), do: {:continue, command}

  defp learn_mode(mode) do
    case mode do
      # ZW_SET_LEARN_MODE_CLASSIC - accept inclusion in direct range only
      :enable -> 0x01
      # ZW_SET_LEARN_MODE_DISABLE - stop learn mode
      :disable -> 0x00
      # ZW_SET_LEARN_MODE_NWI - accept routed inclusion
      :enable_routed -> 0x02
    end
  end
end
