defmodule Grizzly.ZWave.Commands.ApplicationRejectedRequestTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ApplicationRejectedRequest

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = ApplicationRejectedRequest.new(params)
  end
end
