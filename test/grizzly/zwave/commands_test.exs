defmodule Grizzly.ZWave.CommandsTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.DSK

  @special_cases [
    :keep_alive
  ]

  test "command module names match the actual command names" do
    Application.spec(:grizzly, :modules)
    |> Enum.filter(fn mod ->
      case Module.split(mod) do
        # Ignore any modules with more than 4 parts in the module name as they
        # are not commands themselves
        ["Grizzly", "ZWave", "Commands", _] -> true
        _ -> false
      end
    end)
    |> Enum.each(fn mod ->
      # most command modules don't validate anything in new/1, but some do, so
      # we provide valid arguments for those here
      {:ok, cmd} = mod.new(seq_number: 0, dsk: DSK.zeros())

      expected_name =
        mod
        |> Module.split()
        |> List.last()
        |> String.replace("ZWave", "Zwave")
        |> String.replace("MD", "Md")
        |> String.replace("DSK", "Dsk")
        |> String.replace("CRC16", "Crc_16")
        # Add underscore between lowercase and uppercase
        |> String.replace(~r/([a-z0-9])([A-Z])/, "\\1_\\2")
        # Add underscore between consecutive capitals followed by a lowercase
        |> String.replace(~r/([A-Z])([A-Z][a-z])/, "\\1_\\2")
        |> String.downcase()
        |> String.to_atom()

      module_file =
        mod.__info__(:compile)[:source] |> :erlang.list_to_binary() |> Path.relative_to_cwd()

      if cmd.name not in @special_cases do
        assert expected_name == cmd.name, """
        Command name / module name mismatch

          File:           #{module_file}
          Module:         #{inspect(mod)}
          Command name:   #{inspect(cmd.name)}
          Expected name:  #{inspect(expected_name)}
        """
      end
    end)
  end
end
