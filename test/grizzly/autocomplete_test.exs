defmodule Grizzly.AutocompleteTest do
  use ExUnit.Case, async: true

  alias Grizzly.Autocomplete

  test "expands known command names" do
    input = make_input("{:ok, x} = Grizzly.send_command(1, :assoc")
    assert {:yes, expansion, completions} = Autocomplete.expand(input)

    assert expansion == ~c"iation_"
    assert ~c"association_set" in completions
    assert ~c"association_get" in completions
    assert ~c"association_group_info_get" in completions

    input = make_input("{:ok, x} = Grizzly.send_command(1, :association_g")
    assert {:yes, expansion, completions} = Autocomplete.expand(input)

    assert expansion == ~c""
    refute ~c"association_set" in completions
    assert ~c"association_get" in completions
    assert ~c"association_group_info_get" in completions

    input = make_input("{:ok, x} = Grizzly.send_command(1, :rs")
    assert {:yes, expansion, completions} = Autocomplete.expand(input)

    assert expansion == ~c"si_get"
    assert [] == completions
  end

  test "no matches" do
    input = make_input("{:ok, x} = Grizzly.send_command(1, :xyz")
    assert {:no, ~c"", []} = Autocomplete.expand(input)
  end

  test "only completes atoms" do
    input = make_input("{:ok, x} = Grizzly.send_command(1, association_")
    assert {:no, ~c"", []} = Autocomplete.expand(input)
  end

  test "allows variables for first argument" do
    input = make_input("{:ok, x} = Grizzly.send_command(node_id, :rs")
    assert {:yes, ~c"si_get", []} = Autocomplete.expand(input)
  end

  test "does not run in other functions" do
    input = make_input("Grizzly.send_binary(12, :rs")
    assert {:no, ~c"", []} = Autocomplete.expand(input)
  end

  defp make_input(str), do: String.reverse(str) |> String.to_charlist()
end
