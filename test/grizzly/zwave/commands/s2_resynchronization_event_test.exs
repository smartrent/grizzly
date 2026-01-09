defmodule Grizzly.ZWave.Commands.S2ResynchronizationEventTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.S2ResynchronizationEvent

  test "creates the command and validates params" do
    params = [node_id: 5, reason: 0]
    {:ok, _command} = Commands.create(:s2_resynchronization_event, params)
  end

  test "encodes params correctly" do
    params = [node_id: 5, reason: 0]
    {:ok, command} = Commands.create(:s2_resynchronization_event, params)
    expected_binary = <<5, 0, 0, 5>>
    assert expected_binary == S2ResynchronizationEvent.encode_params(command)

    params = [node_id: 0x100, reason: 0]
    {:ok, command} = Commands.create(:s2_resynchronization_event, params)
    expected_binary = <<0xFF, 0x00, 0x01, 0x00>>
    assert expected_binary == S2ResynchronizationEvent.encode_params(command)
  end

  test "decodes  params correctly" do
    binary_params = <<5, 0>>
    {:ok, params} = S2ResynchronizationEvent.decode_params(binary_params)
    assert Keyword.get(params, :node_id) == 5
    assert Keyword.get(params, :reason) == 0
  end

  test "parse version 3 - 8 bit node id" do
    binary = <<0x04, 0x00, 0x00, 0x00>>

    {:ok, params} = S2ResynchronizationEvent.decode_params(binary)

    assert params[:node_id] == 0x04
    assert params[:reason] == 0x00
  end

  test "parse version 3 - 16 bit node id" do
    binary = <<0xFF, 0x00, 0x01, 0x00>>

    {:ok, params} = S2ResynchronizationEvent.decode_params(binary)

    assert params[:node_id] == 0x0100
    assert params[:reason] == 0x00
  end
end
