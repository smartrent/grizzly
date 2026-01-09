defmodule Grizzly.ZWave.Commands.IncludedNIFReport do
  @moduledoc """
  This command is sent by Z/IP Gateway to the unsolicited destination(s) when a
  SmartStart Included Node Information Frame (NIF) is received and both of the
  following conditions are fulfilled:

  * The advertised NWI Home ID (bytes 9-12 of the node's DSK) matches a DSK on
    the provisioning list
  * The advertised Home ID is different from the current network Home ID

  This indicates that the a SmartStart node on the provisioning list is included
  into a different network and must be excluded/reset before it can be included.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DSK

  @type param :: {:seq_number, byte()} | {:dsk, DSK.t()}

  @impl Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    sequence_number = Command.param!(command, :seq_number)
    %DSK{raw: dsk} = Command.param!(command, :dsk)

    <<sequence_number, 0::3, byte_size(dsk)::5, dsk::binary>>
  end

  @impl Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<seq_number::8, _::3, dsk_length::5, dsk::binary-size(dsk_length)>>) do
    {:ok, seq_number: seq_number, dsk: DSK.new(dsk)}
  end
end
