defmodule Grizzly.ZWave.Commands.WakeUpNoMoreInformationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WakeUpNoMoreInformation

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = WakeUpNoMoreInformation.new(params)
  end
end
