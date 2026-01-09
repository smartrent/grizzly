defmodule Grizzly.ZWave.Commands.NetworkUpdateRequestStatusTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.NetworkUpdateRequestStatus

  test "creates the command and validates params" do
    params = [seq_number: 2, status: :done]
    {:ok, _command} = Commands.create(:network_update_request_status, params)
  end

  test "encodes params correctly" do
    params = [seq_number: 2, status: :done]
    {:ok, command} = Commands.create(:network_update_request_status, params)
    expected_binary = <<0x02, 0x00>>
    assert expected_binary == NetworkUpdateRequestStatus.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x00>>
    {:ok, params} = NetworkUpdateRequestStatus.decode_params(binary_params)
    assert Keyword.get(params, :seq_number) == 2
    assert Keyword.get(params, :status) == :done
  end
end
