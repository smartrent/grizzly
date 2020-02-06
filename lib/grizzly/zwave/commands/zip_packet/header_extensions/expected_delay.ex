defmodule Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions.ExpectedDelay do
  @moduledoc """
  Expected Delay is the header extension that is found in a
  Z/IP Command to indicate how many seconds until the command will be
  received by a node and processed.

  - Non-Sleeping devices: this extension does not apply
  - Frequently Listening Nodes: 1 seconds
  - Sleeping devices: > 1
  """

  @spec to_binary(Grizzly.ZWave.Command.delay_seconds()) :: binary()
  def to_binary(expected_delay) do
    <<0x01, 0x03, expected_delay::integer-size(3)-unit(8)>>
  end
end
