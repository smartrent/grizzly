defmodule Grizzly.ZWave.Commands.PriorityRouteSet do
  @moduledoc """
  This command is used to set the network route to use when sending commands to
  the specified NodeID. This route will override the normal routing table.

  The use of this command is NOT RECOMMENDED.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance, as: NMIM
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:node_id, byte()}
          | {:repeaters, [byte()]}
          | {:speed, NMIM.speed()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    repeater_bytes = Command.param!(command, :repeaters) |> NMIM.repeaters_to_bytes()
    speed_byte = Command.param!(command, :speed) |> NMIM.speed_to_byte()

    <<node_id, repeater_bytes::binary, speed_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<node_id, repeater_bytes::binary-size(4), speed_byte>>) do
    with {:ok, speed} <- NMIM.speed_from_byte(speed_byte) do
      {:ok,
       [
         node_id: node_id,
         speed: speed,
         repeaters: NMIM.repeaters_from_bytes(repeater_bytes)
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :priority_route_report}}
    end
  end
end
