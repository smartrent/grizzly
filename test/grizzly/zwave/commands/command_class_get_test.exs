defmodule Grizzly.ZWave.Commands.CommandClassGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.CommandClassGet

  test "creates the command and validates params" do
    params = [command_class: :association_get]
    {:ok, _command} = CommandClassGet.new(params)
  end

  test "encodes params correctly" do
    params = [command_class: :basic]
    {:ok, command} = CommandClassGet.new(params)
    expected_params_binary = <<0x20>>
    assert expected_params_binary == CommandClassGet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x20>>
    {:ok, params} = CommandClassGet.decode_params(params_binary)
    assert Keyword.get(params, :command_class) == :basic
  end
end
