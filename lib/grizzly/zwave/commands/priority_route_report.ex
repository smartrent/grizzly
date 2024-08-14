defmodule Grizzly.ZWave.Commands.PriorityRouteReport do
  @moduledoc """
  This command is used to advertise the current network route in use for an actual destination NodeID.

  Params:

    * `:node_id` - the NodeID destination for which the current network route is requested (required)

    * `:type` - the route type (required)

    * `:repeaters` - node ids of repeaters for the route (required)

    * `:speed` - speeds used for the route (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance, as: NMIM

  @type param ::
          {:node_id, byte}
          | {:type, NMIM.route_type()}
          | {:repeaters, [byte]}
          | {:speed, NMIM.speed()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :priority_route_report,
      command_byte: 0x03,
      command_class: NMIM,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    type_byte = Command.param!(command, :type) |> NMIM.route_type_to_byte()
    repeater_bytes = Command.param!(command, :repeaters) |> NMIM.repeaters_to_bytes()
    speed_byte = Command.param!(command, :speed) |> NMIM.speed_to_byte()

    <<node_id, type_byte>> <> repeater_bytes <> <<speed_byte>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<node_id, type_byte, repeater_bytes::binary-size(4), speed_byte>>) do
    with {:ok, type} <- NMIM.route_type_from_byte(type_byte),
         {:ok, speed} <- NMIM.speed_from_byte(speed_byte) do
      {:ok,
       [
         node_id: node_id,
         type: type,
         speed: speed,
         repeaters: NMIM.repeaters_from_bytes(repeater_bytes)
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :priority_route_report}}
    end
  end
end
