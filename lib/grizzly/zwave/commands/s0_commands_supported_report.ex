defmodule Grizzly.ZWave.Commands.S0CommandsSupportedReport do
  @moduledoc """
  Lists commands supported by a node when using S0.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, CommandClasses, DecodeError}
  alias Grizzly.ZWave.CommandClasses.S0

  @type param ::
          {:supported | :controlled, [CommandClasses.command_class()]}
          | {:reports_to_follow, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :s0_commands_supported_report,
      command_byte: 0x03,
      command_class: S0,
      params: put_defaults(params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(cmd) do
    supported = Command.param!(cmd, :supported)
    controlled = Command.param!(cmd, :controlled)
    reports_to_follow = Command.param!(cmd, :reports_to_follow)

    ccs = supported ++ [:mark] ++ controlled

    for cc <- ccs, into: <<reports_to_follow::8>> do
      <<CommandClasses.to_byte(cc)>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<reports_to_follow::8, rest::binary>>) do
    {supported, controlled} =
      rest
      |> :erlang.binary_to_list()
      |> Enum.map(&elem(CommandClasses.from_byte(&1), 1))
      |> Enum.split_while(&(&1 != :mark))
      |> case do
        {supported, [:mark | controlled]} -> {supported, controlled}
        # for safety, if COMMAND_CLASS_MARK is missing, assume none of the supported CCs are controlled
        {supported, []} -> {supported, []}
      end

    {:ok, [reports_to_follow: reports_to_follow, supported: supported, controlled: controlled]}
  end

  defp put_defaults(params) do
    params
    |> Keyword.put_new(:supported, [])
    |> Keyword.put_new(:controlled, [])
    |> Keyword.put_new(:reports_to_follow, 0)
  end
end
