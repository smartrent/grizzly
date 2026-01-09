defmodule Grizzly.ZWave.Commands.NetworkUpdateRequestTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkUpdateRequest

  test "creates the command and validates params" do
    params = [seq_number: 2]
    {:ok, _command} = Commands.create(:network_update_request, params)
  end

  test "encodes params correctly" do
    params = [seq_number: 2]
    {:ok, command} = Commands.create(:network_update_request, params)
    expected_binary = <<0x02>>
    assert expected_binary == NetworkUpdateRequest.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02>>
    {:ok, params} = NetworkUpdateRequest.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 2
  end
end
