defmodule Grizzly.ZWave.Commands.UserCodeChecksumReport do
  @moduledoc """
  What does this command do??

  Params:

  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.Command

  @type param :: {:checksum, 0x0000..0xFFFF}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    checksum = Command.param!(command, :checksum)
    msb = checksum >>> 8
    lsb = checksum &&& 0xFF
    <<msb::8, lsb::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<msb::8, lsb::8>>) do
    {:ok, [checksum: msb <<< 8 ||| lsb]}
  end
end
