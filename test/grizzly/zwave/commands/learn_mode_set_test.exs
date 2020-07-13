defmodule Grizzly.ZWave.Commands.LearnModeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.LearnModeSet

  test "creates the command and validates params" do
    params = [seq_number: 3, return_interview_status: :on, mode: :allow_routed]
    {:ok, _command} = LearnModeSet.new(params)
  end

  test "encodes params correctly" do
    params = [seq_number: 3, return_interview_status: :on, mode: :allow_routed]
    {:ok, command} = LearnModeSet.new(params)
    expected_binary = <<0x03, 0x01, 0x02>>
    assert expected_binary == LearnModeSet.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x03, 0x01, 0x02>>
    {:ok, params} = LearnModeSet.decode_params(params_binary)
    assert Keyword.get(params, :seq_number) == 3
    assert Keyword.get(params, :return_interview_status) == :on
    assert Keyword.get(params, :mode) == :allow_routed
  end
end
