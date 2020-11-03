defmodule Grizzly.ZWave.Commands.StatisticsClear do
  @moduledoc """
  This command is used to clear all statistic registers maintained by the node.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @impl true
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

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
