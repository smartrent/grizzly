defmodule Grizzly.CommandDecoder do
  @moduledoc false

  alias Grizzly.ZWaveCommand

  def from_binary(<<0x25, 0x01, _rest::binary>> = binary),
    do: decode(Grizzly.Commands.SwitchBinarySet, binary)

  defp decode(module, binary) do
    ZWaveCommand.from_binary(struct(module), binary)
  end
end
