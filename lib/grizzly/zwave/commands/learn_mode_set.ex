defmodule Grizzly.ZWave.Commands.LearnModeSet do
  @moduledoc """
  This command is used to allow a node to be added to (or removed from) the network. When a node is
  added to the network, the node is assigned a valid Home ID and NodeID.

  Params:

    * `:seq_number` - a command sequence number

    * `:return_interview_status` - This field is used to request that the receiving node returns an additional Learn Mode Set Status
                                  Command when the node interview is completed. It is set to either :on or :off. (optional - defaults to :off)

    * `:mode` - The Mode field controls operation to one of :disable, :direct_range_only (immediate range inclusions only), or :allow_routed (accept routed inclusion)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode

  @type mode :: :disable | :direct_range_only | :allow_routed
  @type param ::
          {:seq_number, ZWave.seq_number()}
          | {:return_interview_status, :on | :off}
          | {:mode, mode}

  @impl true
  def new(params) do
    command = %Command{
      name: :learn_mode_set,
      command_byte: 0x01,
      command_class: NetworkManagementBasicNode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)

    return_interview_status_bit =
      Command.param(command, :return_interview_status, :off) |> encode_return_interview_status()

    mode_byte = Command.param!(command, :mode) |> encode_mode()
    <<seq_number, 0x00::7, return_interview_status_bit::1, mode_byte>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, 0x00::7, return_interview_status_bit::1, mode_byte>>) do
    return_interview_status = decode_return_interview_status(return_interview_status_bit)

    with {:ok, mode} <- decode_mode(mode_byte) do
      {:ok,
       [seq_number: seq_number, return_interview_status: return_interview_status, mode: mode]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_return_interview_status(:on), do: 1
  defp encode_return_interview_status(:off), do: 0

  defp encode_mode(:disable), do: 0x00
  defp encode_mode(:direct_range_only), do: 0x01
  defp encode_mode(:allow_routed), do: 0x02

  defp decode_return_interview_status(0), do: :off
  defp decode_return_interview_status(1), do: :on

  defp decode_mode(0x00), do: {:ok, :disable}
  defp decode_mode(0x01), do: {:ok, :direct_range_only}
  defp decode_mode(0x02), do: {:ok, :allow_routed}

  defp decode_mode(byte),
    do: {:error, %DecodeError{value: byte, param: :mode, command: :learn_mode_set}}
end
