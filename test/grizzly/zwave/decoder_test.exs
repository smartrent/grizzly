defmodule Grizzly.ZWave.DecoderTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Decoder

  test "all entries map to a module that actually exists" do
    Decoder.__mappings__()
    |> Enum.each(&Code.ensure_loaded!(elem(&1, 1)))
  end
end
