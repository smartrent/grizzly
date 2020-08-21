defmodule Grizzly.ZWave.Commands.ApplicationBusyTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ApplicationBusy

  test "creates the command and validates params" do
    params = [status: :try_again_after_wait, wait_time: 2]
    {:ok, _command} = ApplicationBusy.new(params)
  end

  test "encodes params correctly" do
    params = [status: :try_again_after_wait, wait_time: 2]
    {:ok, command} = ApplicationBusy.new(params)
    expected_params_binary = <<0x01, 0x02>>
    assert expected_params_binary == ApplicationBusy.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x01, 0x02>>
    {:ok, params} = ApplicationBusy.decode_params(params_binary)
    assert Keyword.get(params, :status) == :try_again_after_wait
    assert Keyword.get(params, :wait_time) == 2
  end
end
