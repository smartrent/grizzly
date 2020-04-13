defmodule Grizzly.ZWave.Commands.NodeAddDSKSet do
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_add_dsk_set,
      command_byte: 0x14,
      command_class: NetworkManagementInclusion,
      params: params,
      # TODO: probably not right
      handler: AckResponse,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    accept = Command.param!(command, :accept)
    input_dsk_length = Command.param!(command, :input_dsk_length)
    input_dsk = Command.param(command, :input_dsk, 0)

    dsk = <<input_dsk::size(input_dsk_length)-unit(8)>>

    <<seq_number, bool_to_bit(accept)::size(1), 0::size(3), input_dsk_length::size(4)>> <> dsk
  end

  @impl true
  def decode_params(
        <<seq_number, accept::size(1), _::size(3), input_dsk_length::size(4),
          input_dsk::size(input_dsk_length)-unit(8)>>
      ) do
    [
      seq_number: seq_number,
      accept: bit_to_bool(accept),
      input_dsk_length: input_dsk_length,
      input_dsk: input_dsk
    ]
  end

  defp bool_to_bit(true), do: 1
  defp bool_to_bit(false), do: 0

  defp bit_to_bool(1), do: true
  defp bit_to_bool(0), do: false
end
