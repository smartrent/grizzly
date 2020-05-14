defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.UserCodeUsersNumberGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = UserCodeUsersNumberGet.new(params)
  end
end
