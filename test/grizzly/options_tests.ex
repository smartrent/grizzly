defmodule Grizzly.OptionsTest do
  use ExUnit.Case, async: true

  alias Grizzly.Options
  alias Grizzly.ZIPGateway.Config

  test "to Z/IP Gateway config" do
    options = Options.new()

    assert Config.new() == Options.to_zipgateway_config(options)
  end
end
