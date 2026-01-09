defmodule Grizzly.ZWave.Commands.UserCodeChecksumReport do
  @moduledoc """
  What does this command do??

  Params:

  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param :: {:checksum, 0x0000..0xFFFF}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    checksum = Command.param!(command, :checksum)
    msb = checksum >>> 8
    lsb = checksum &&& 0xFF
    <<msb::8, lsb::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<msb::8, lsb::8>>) do
    {:ok, [checksum: msb <<< 8 ||| lsb]}
  end
end
