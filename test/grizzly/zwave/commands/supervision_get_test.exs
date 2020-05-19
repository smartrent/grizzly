defmodule Grizzly.ZWave.Commands.SupervisionGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SupervisionGet

  test "creates the command and validates params" do
    params = [
      status_updates: :one_now,
      session_id: 1,
      encapsulated_command: <<113, 5, 25, 1, 0, 255, 6, 4, 0>>
    ]

    {:ok, _command} = SupervisionGet.new(params)
  end

  test "encodes params correctly" do
    params = [
      status_updates: :one_now,
      session_id: 1,
      encapsulated_command: <<113, 5, 25, 1, 0, 255, 6, 4, 0>>
    ]

    {:ok, command} = SupervisionGet.new(params)

    expected_binary = <<0x01, 0x09, 113, 5, 25, 1, 0, 255, 6, 4, 0>>

    assert expected_binary == SupervisionGet.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x01, 0x09, 113, 5, 25, 1, 0, 255, 6, 4, 0>>

    {:ok, params} = SupervisionGet.decode_params(binary_params)
    assert Keyword.get(params, :status_updates) == :one_now
    assert Keyword.get(params, :session_id) == 1
    assert Keyword.get(params, :encapsulated_command) == <<113, 5, 25, 1, 0, 255, 6, 4, 0>>
  end
end
