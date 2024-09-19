defmodule Grizzly.ZWave.Commands.RssiGet do
  @moduledoc """
  This command is used to query the measured RSSI on the Z-Wave network from a node.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :rssi_get,
      command_byte: 0x07,
      command_class: NetworkManagementInstallationMaintenance,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
