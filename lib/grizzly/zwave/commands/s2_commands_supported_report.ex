defmodule Grizzly.ZWave.Commands.S2CommandsSupportedReport do
  @moduledoc """
  Lists commands supported by a node when using S2.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses

  @type param ::
          {:command_classes, [CommandClasses.command_class()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, cmd) do
    ccs = Command.param!(cmd, :command_classes)

    for cc <- ccs, into: <<>> do
      <<CommandClasses.to_byte(cc)>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    ccs =
      binary
      |> :erlang.binary_to_list()
      |> Enum.map(&elem(CommandClasses.from_byte(&1), 1))

    {:ok, [command_classes: ccs]}
  end
end
