defmodule Grizzly.Client.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Client

  test "make a Client struct" do
    assert Client.new(:fake, {127, 0, 0, 1}, 12345) == %Client{
             module: :fake,
             ip_address: {127, 0, 0, 1},
             socket: nil,
             port: 12345
           }
  end
end
