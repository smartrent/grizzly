defmodule Grizzly.InclusionHandler do
  @moduledoc """
  Behaviour for handling incoming commands during the inclusion process

  During the inclusion process different Z-Wave commands can be exchanged
  asynchronously. One way to handle this is by wrapping `Grizzly.Inclusions`
  in a `GenServer`, but that is a lot of work for something Grizzly can provide
  out of the box.

  When you initialize an inclusion process you can pass the `:handler` option
  to the function which can either be the a `pid` (defaults to caller pid) or a
  module that implements this behaviour.

  These reports this callback function will want to handle are:

  - `Grizzly.ZWave.Commands.NodeAddStatus`
  - `Grizzly.ZWave.Commands.NodeRemoveStatus`
  - `Grizzly.ZWave.Commands.NodeAddDSKReport`
  - `Grizzly.ZWave.Commands.NodeAddKeysReport`

  If you are not handling S2 devices the last two can be ignored until you are
  ready to provide support them.
  """

  alias Grizzly.ZWave.Command

  @callback handle_command(Command.t(), keyword()) :: :ok
end
