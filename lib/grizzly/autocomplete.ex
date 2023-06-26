defmodule Grizzly.Autocomplete do
  @moduledoc """
  Adds command completion to the default IEx autocomplete.

  This module augments the IEx autocompletion logic to complete Grizzly
  command names inside of `Grizzly.send_command/4` calls.

  Call `Grizzly.Autocomplete.set_expand_fun()` (or put it in your `.iex.exs`) to
  enable this feature.
  """

  require Logger

  def expand(expr) do
    str = Enum.reverse(expr) |> to_string()

    with {:unquoted_atom, partial_command_name} <- Code.Fragment.cursor_context(str),
         {:ok, ast} = Code.Fragment.container_cursor_to_quoted(str),
         true <- in_send_command_call?(ast) do
      partial_command_name
      |> to_string()
      |> expand_command()
    else
      _ ->
        IEx.Autocomplete.expand(expr)
    end
  rescue
    err ->
      Logger.error("""
      Error during autocomplete expansion: #{inspect(err)}

      Ejecting `Grizzly.Autocomplete` and restoring default IEx autocomplete.
      """)

      gl = Process.group_leader()
      _ = :io.setopts(gl, expand_fun: &IEx.Autocomplete.expand/1)
  end

  defp expand_command(command_prefix) do
    expansions =
      Enum.reduce(Grizzly.list_commands(), [], fn command, acc ->
        command_str = Atom.to_string(command)

        if String.starts_with?(command_str, command_prefix) do
          [command_str | acc]
        else
          acc
        end
      end)

    prefix_len = String.length(command_prefix)

    case expansions do
      [] ->
        {:no, ~c"", []}

      [^command_prefix] ->
        {:no, ~c"", []}

      [unique] ->
        completion = unique |> String.to_charlist() |> Enum.drop(prefix_len)
        {:yes, completion, []}

      list ->
        list = Enum.map(list, &String.to_charlist/1)

        completion = list |> Enum.reduce(&common_prefix/2) |> Enum.drop(prefix_len)

        {:yes, completion, list}
    end
  end

  # Find the common prefix for two charlists
  defp common_prefix(a, b, acc \\ [])

  defp common_prefix([h | t1], [h | t2], acc) do
    common_prefix(t1, t2, [h | acc])
  end

  defp common_prefix(_, _, acc) do
    Enum.reverse(acc)
  end

  defp in_send_command_call?(ast) do
    {_, yes?} =
      Macro.postwalk(ast, false, fn
        {{:., _, [{:__aliases__, _, [:Grizzly]}, :send_command]}, _, [_, {:__cursor__, _, _}]},
        acc ->
          {ast, acc || true}

        ast, acc ->
          {ast, acc || false}
      end)

    yes?
  end

  # The following are adapted from IEx.Autocomplete

  # Provides a helper function that is injected into connecting remote nodes to
  # properly handle autocompletion.
  @doc false
  def remsh(node) do
    fn e ->
      case :rpc.call(node, Grizzly.Autocomplete, :expand, [e]) do
        {:badrpc, _} -> {:no, ~c"", []}
        r -> r
      end
    end
  end

  @spec set_expand_fun() :: :ok | {:error, any}
  def set_expand_fun() do
    gl = Process.group_leader()

    expand_fun =
      if node(gl) != node() do
        Grizzly.Autocomplete.remsh(node())
      else
        &Grizzly.Autocomplete.expand/1
      end

    # expand_fun is not supported by a shell variant
    # on Windows, so we do two IO calls, not caring
    # about the result of the expand_fun one.
    _ = :io.setopts(gl, expand_fun: expand_fun)
    :io.setopts(gl, binary: true, encoding: :unicode)
  end
end
