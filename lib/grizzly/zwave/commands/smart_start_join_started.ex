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

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.DSK

  @type param ::
          {:seq_number, Grizzly.ZWave.seq_number()}
          | {:dsk, DSK.t()}

  @impl Grizzly.ZWave.Command
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

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    dsk = Command.param!(command, :dsk)
    dsk_byte_size = byte_size(dsk.raw)

    <<seq_number, 0x00::3, dsk_byte_size::5>> <> dsk.raw
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<seq_number, _::3, dsk_byte_size::5, dsk_binary::binary-size(dsk_byte_size)-unit(8)>>
      ) do
    {:ok,
     [
       seq_number: seq_number,
       dsk: DSK.new(dsk_binary)
     ]}
  end
end
