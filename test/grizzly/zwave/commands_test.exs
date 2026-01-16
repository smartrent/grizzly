defmodule Grizzly.ZWave.CommandsTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  doctest Grizzly.ZWave.Commands

  test "no unused command modules" do
    command_modules =
      Application.spec(:grizzly, :modules)
      |> Enum.filter(&match?(["Grizzly", "ZWave", "Commands", _], Module.split(&1)))
      |> MapSet.new()

    used_command_modules =
      Grizzly.list_commands() |> Enum.map(&Commands.spec_for!(&1).module) |> MapSet.new()

    diff = MapSet.difference(command_modules, used_command_modules)

    assert Enum.empty?(diff), """
    The following command modules are not used by any of the commands listed in Grizzly.list_commands/0:

      * #{Enum.map_join(diff, "\n  * ", &inspect/1)}
    """
  end
end
