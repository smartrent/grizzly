defmodule Grizzly.BackendBuildTest do
  use ExUnit.Case, async: false

  test "legacy build does not compile or load the native backend" do
    assert Grizzly.Backend.name() == :zipgateway
    assert :code.which(Grizzly.Backends.Zwrap) == :non_existing
    assert :code.which(Zwrap) == :non_existing
    assert_raise ArgumentError, fn -> Grizzly.Options.new(backend: :zwrap) end
    Application.put_env(:grizzly, :backend, :zwrap)

    try do
      assert_raise ArgumentError, fn -> Grizzly.Options.new() end
    after
      Application.put_env(:grizzly, :backend, :zipgateway)
    end
  end
end
