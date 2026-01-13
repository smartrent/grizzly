defmodule Grizzly.ZWave.Commands.UserCodeGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserCodeGet

  test "creates the command and validates params" do
    params = [user_id: 2]
    {:ok, _command} = Commands.create(:user_code_get, params)
  end

  test "encodes params correctly" do
    params = [user_id: 2]
    {:ok, command} = Commands.create(:user_code_get, params)

    expected_binary = <<0x02>>

    assert expected_binary == UserCodeGet.encode_params(nil, command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>

    {:ok, params} = UserCodeGet.decode_params(nil, binary_params)
    assert Keyword.get(params, :user_id) == 2
  end
end
