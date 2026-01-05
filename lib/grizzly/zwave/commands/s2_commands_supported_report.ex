defmodule Grizzly.ZWave.Commands.S2CommandsSupportedReport do
  @moduledoc """
  Lists commands supported by a node when using S2.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:command_classes, [CommandClasses.command_class()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :s2_commands_supported_report,
      command_byte: 0x0E,
      command_class: Security2,
      params: put_defaults(params)
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(cmd) do
    ccs = Command.param!(cmd, :command_classes)

    for cc <- ccs, into: <<>> do
      <<CommandClasses.to_byte(cc)>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    ccs =
      binary
      |> :erlang.binary_to_list()
      |> Enum.map(&elem(CommandClasses.from_byte(&1), 1))

    {:ok, [command_classes: ccs]}
  end

  defp put_defaults(params) do
    params
    |> Keyword.put_new(:command_classes, [])
  end
end
