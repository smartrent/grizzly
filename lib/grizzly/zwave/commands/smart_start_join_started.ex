defmodule Grizzly.ZWave.Commands.SmartStartJoinStarted do
  @moduledoc """
  This command is sent to the unsolicited destinations when a Smart Start
  inclusion starts.

  The Add Node Status Command MUST be issued after the Smart Start inclusion and S2 bootstrapping
  attempts took place.

  Params:
    `:seq_number` - the sequence number for the networked command (required)
  * `:dsk` - a DSK string for the device see `Grizzly.ZWave.DSK` for more more information (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError, DSK}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type param ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:dsk, DSK.dsk_string()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :smart_start_join_started,
      command_byte: 0x15,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    {:ok, dsk_binary} = Command.param!(command, :dsk) |> DSK.string_to_binary()
    dsk_byte_size = byte_size(dsk_binary)

    <<seq_number, 0x00::size(3), dsk_byte_size::size(5)>> <> dsk_binary
  end

  @impl true
  def decode_params(
        <<seq_number, _::size(3), dsk_byte_size::size(5),
          dsk_binary::size(dsk_byte_size)-unit(8)-binary>>
      ) do
    with {:ok, dsk_string} <- DSK.binary_to_string(dsk_binary) do
      {:ok,
       [
         seq_number: seq_number,
         dsk: dsk_string
       ]}
    else
      {:error, _reason} ->
        {:error, %DecodeError{value: dsk_binary, param: :dsk, command: :smart_start_join_started}}
    end
  end
end
