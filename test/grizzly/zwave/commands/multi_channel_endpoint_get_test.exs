defmodule Grizzly.ZWave.Commands.MultiChannelEndpointGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MultiChannelEndpointGet

  test "creates the command and validates params" do
    {:ok, _command} = MultiChannelEndpointGet.new([])
  end
end
