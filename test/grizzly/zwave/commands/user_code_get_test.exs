defmodule Grizzly.ZWave.Commands.UserCodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.UserCodeGet

  test "creates the command and validates params" do
    params = [user_id: 2]
    {:ok, _command} = UserCodeGet.new(params)
  end

  test "encodes params correctly" do
    params = [user_id: 2]
    {:ok, command} = UserCodeGet.new(params)

    expected_binary = <<0x02>>

    assert expected_binary == UserCodeGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>

    {:ok, params} = UserCodeGet.decode_params(binary_params)
    assert Keyword.get(params, :user_id) == 2
  end
end
