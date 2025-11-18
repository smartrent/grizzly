defmodule Grizzly.ZWave.CommandsTest do
  use ExUnit.Case, async: true

  alias Grizzly.Requests.Handlers.WaitReport
  alias Grizzly.ZWave.{Commands, DSK}

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

  # There was a good reason for this exception at one point, but I don't remember
  # what it was. :shrug:
  @no_validate [:multi_channel_get_command_encapsulation]

  test "all entries map to a module that actually exists" do
    for {table_name, handler_spec} <- Commands.dump() do
      {command_module, opts} = Commands.format_handler_spec(handler_spec)

      assert Code.ensure_loaded?(command_module)

      {:ok, cmd} = command_module.new([])

      if table_name not in @no_validate do
        assert cmd.name == table_name, """
        Command name mismatch

          Grizzly.Commands.Table:   #{inspect(table_name)}
          Command module:           #{inspect(cmd.name)}

        The correct resolution is usually to update the command module's name to match
        the name in `Grizzly.Commands.Table`.
        """
      end

      case opts[:handler] do
        {WaitReport, handler_opts} ->
          assert handler_opts[:complete_report], """
          The command named #{inspect(table_name)} has a handler of WaitReport with no
          `complete_report` option.
          """

          assert find_module_with_command_name(handler_opts[:complete_report]), """
          No module found under Grizzly.ZWave.Commands with the name #{inspect(handler_opts[:complete_report])}
          """

        _ ->
          :ok
      end
    end
  end

  # special case
  defp find_module_with_command_name(:any), do: true

  defp find_module_with_command_name(command_name) do
    Application.spec(:grizzly, :modules)
    |> Enum.filter(fn mod ->
      case Module.split(mod) do
        ["Grizzly", "ZWave", "Commands" | _] -> true
        _ -> false
      end
    end)
    |> Enum.any?(fn mod ->
      if Code.ensure_loaded?(mod) && function_exported?(mod, :new, 1) do
        # most command modules don't validate anything in new/1, but some do, so
        # we provide valid arguments for those here
        {:ok, cmd} = mod.new(seq_number: 0, dsk: DSK.zeros())
        cmd.name == command_name
      else
        false
      end
    end)
  end
end
