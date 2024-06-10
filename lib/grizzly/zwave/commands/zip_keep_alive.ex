defmodule Grizzly.ZWave.Commands.ZIPKeepAlive do
  @moduledoc """
  The Z/IP Packet keep alive command

  Params:

    * `:ack_flag` - the flag if the receiving node should acknowledge the
       keep alive packet or not
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ZIP

  @type ack_flag :: :ack_response | :ack_request

  @type param :: {:ack_flag, ack_flag()}

  @impl true
  @spec new(keyword()) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :keep_alive,
      command_byte: 0x03,
      command_class: ZIP,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(params) do
    ack_flag = Command.param!(params, :ack_flag)
    <<encode_ack_flag(ack_flag)>>
  end

  @impl true
  def decode_params(<<1::1, _::7>>), do: {:ok, [ack_flag: :ack_request]}
  def decode_params(<<0::1, 1::1, _::6>>), do: {:ok, [ack_flag: :ack_response]}

  def decode_params(<<ack_flag>>),
    do: {:error, %DecodeError{value: ack_flag, param: :ack_flag, command: :keep_alive}}

  @spec encode_ack_flag(ack_flag()) :: byte()
  def encode_ack_flag(:ack_response), do: 0x40
  def encode_ack_flag(:ack_request), do: 0x80
end
