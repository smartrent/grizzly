defmodule Grizzly.NativeBuildTest do
  use ExUnit.Case, async: false

  test "startup and runtime settings cannot select a different backend" do
    selected = Grizzly.Backend.name()
    other = if Grizzly.Backend.zwrap?(), do: :zipgateway, else: :zwrap
    assert_raise ArgumentError, fn -> Grizzly.Options.new(backend: other) end
    Application.put_env(:grizzly, :backend, other)

    try do
      assert_raise ArgumentError, fn -> Grizzly.Options.new() end
    after
      Application.put_env(:grizzly, :backend, selected)
    end
  end

  test "native build has no legacy controller, transport, dependencies or assets" do
    for module <- [
          Grizzly.ZIPGateway,
          Grizzly.ZIPGateway.Supervisor,
          Grizzly.Backends.Zipgateway,
          Grizzly.Transport,
          Grizzly.Transports.DTLS,
          Grizzly.UnsolicitedServer.ConnectionHandler,
          MuonTrap,
          ThousandIsland,
          BEAMNotify
        ] do
      assert :code.which(module) == :non_existing
    end

    assert File.ls!(Application.app_dir(:grizzly, "priv")) == []
    assert Grizzly.Backend.name() == :zwrap
  end

end
