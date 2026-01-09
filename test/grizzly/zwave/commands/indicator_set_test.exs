defmodule Grizzly.ZWave.Commands.IndicatorSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.IndicatorSet

  describe "creates the command and validates params" do
    test "v1" do
      params = [value: 0]
      {:ok, _command} = Commands.create(:indicator_set, params)
    end

    test "v2" do
      params = [
        resources: [
          [indicator_id: :armed, property_id: :binary, value: :on],
          [indicator_id: :ready, property_id: :multilevel, value: :off]
        ]
      ]

      {:ok, _command} = Commands.create(:indicator_set, params)
    end
  end

  describe "encodes params correctly" do
    test "v1" do
      params = [value: 0]
      {:ok, command} = Commands.create(:indicator_set, params)
      expected_params_binary = <<0x00>>
      assert expected_params_binary == IndicatorSet.encode_params(command)
    end

    test "v2" do
      params = [
        resources: [
          [indicator_id: :armed, property_id: :binary, value: :on],
          [indicator_id: :ready, property_id: :multilevel, value: :off]
        ]
      ]

      {:ok, command} = Commands.create(:indicator_set, params)
      expected_params_binary = <<0x00, 0x02, 0x01, 0x02, 0xFF, 0x03, 0x01, 0x00>>
      assert expected_params_binary == IndicatorSet.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1" do
      params_binary = <<0x01>>
      {:ok, params} = IndicatorSet.decode_params(params_binary)
      assert Keyword.get(params, :value) == 0x01
    end

    test "v2" do
      params_binary = <<0x00, 0x02, 0x01, 0x02, 0xFF, 0x03, 0x01, 0x00>>
      {:ok, params} = IndicatorSet.decode_params(params_binary)
      [first, second] = Keyword.fetch!(params, :resources) |> Enum.sort()
      assert Keyword.get(first, :indicator_id) == :armed
      assert Keyword.get(first, :property_id) == :binary
      assert Keyword.get(first, :value) == :on
      assert Keyword.get(second, :indicator_id) == :ready
      assert Keyword.get(second, :property_id) == :multilevel
      assert Keyword.get(second, :value) == :off
    end
  end
end
