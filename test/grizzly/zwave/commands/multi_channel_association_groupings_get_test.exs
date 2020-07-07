defmodule Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsGet

  test "creates the command and validates params" do
    {:ok, _command} = MultiChannelAssociationGroupingsGet.new([])
  end
end
