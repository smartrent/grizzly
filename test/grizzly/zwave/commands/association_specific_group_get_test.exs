defmodule Grizzly.ZWave.Commands.AssociationSpecificGroupGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AssociationSpecificGroupGet

  test "creates the command and validates params" do
    {:ok, _command} = AssociationSpecificGroupGet.new([])
  end
end
