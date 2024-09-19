defmodule Grizzly.ZWave.Commands.StatisticsClear do
  @moduledoc """
  This command is used to clear all statistic registers maintained by the node.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :statistics_clear,
      command_byte: 0x06,
      command_class: NetworkManagementInstallationMaintenance,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
