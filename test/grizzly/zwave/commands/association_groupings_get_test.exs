defmodule Grizzly.ZWave.Commands.AssociationGroupingsGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationGroupingsGet

  test "creates the command and validates params" do
    {:ok, _command} = AssociationGroupingsGet.new([])
  end
end
