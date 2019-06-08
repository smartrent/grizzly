defmodule Grizzly.Conn.Config.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Conn.Config
  alias Grizzly.Client.DTLS

  test "defaults to the DTLS client when no client is given" do
    config = Config.new(ip: {0, 0, 0, 0}, port: 5000)
    assert config.client == DTLS
  end
end
