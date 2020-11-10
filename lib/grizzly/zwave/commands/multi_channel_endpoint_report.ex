defmodule Grizzly.ZWave.Commands.MultiChannelEndpointReport do
  @moduledoc """
  This command is used to advertise the number of End Points implemented by the sending node.

  Params:


    * `:dynamic` - whether the node implements a dynamic number of End Points (required)
    * `:identical` - whether all end points have identical capabilities (required)
    * `:endpoints` - the number of endpoints (required)
    * `:aggregated_endpoints` - the number of Aggregated End Points implemented by this node (optional - v4)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param ::
          {:dynamic, boolean}
          | {:identical, boolean}
          | {:endpoints, byte}
          | {:aggregated_endpoints, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_endpoint_report,
      command_byte: 0x08,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    dynamic_bit = if Command.param!(command, :dynamic), do: 0x01, else: 0x00
    identical_bit = if Command.param!(command, :identical), do: 0x01, else: 0x00
    endpoints = Command.param!(command, :endpoints)
    aggregated_endpoints = Command.param(command, :aggregated_endpoints)

    if aggregated_endpoints == nil do
      <<dynamic_bit::size(1), identical_bit::size(1), 0x00::size(6), 0x00::size(1),
        endpoints::size(7)>>
    else
      <<dynamic_bit::size(1), identical_bit::size(1), 0x00::size(6), 0x00::size(1),
        endpoints::size(7), 0x00::size(1), aggregated_endpoints::size(7)>>
    end
  end

  @impl true
  # v4
  def decode_params(
        <<dynamic_bit::size(1), identical_bit::size(1), 0x00::size(6), 0x00::size(1),
          endpoints::size(7), 0x00::size(1), aggregated_endpoints::size(7)>>
      ) do
    dynamic? = dynamic_bit == 0x01
    identical? = identical_bit == 0x01

    {:ok,
     [
       dynamic: dynamic?,
       identical: identical?,
       endpoints: endpoints,
       aggregated_endpoints: aggregated_endpoints
     ]}
  end

  def decode_params(
        <<dynamic_bit::size(1), identical_bit::size(1), 0x00::size(6), 0x00::size(1),
          endpoints::size(7)>>
      ) do
    dynamic? = dynamic_bit == 0x01
    identical? = identical_bit == 0x01

    {:ok,
     [
       dynamic: dynamic?,
       identical: identical?,
       endpoints: endpoints,
       aggregated_endpoints: 0
     ]}
  end
end
