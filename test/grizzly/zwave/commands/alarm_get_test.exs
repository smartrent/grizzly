defmodule Grizzly.ZWave.Commands.AlarmGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmGet

  describe "creates the command and validates params" do
    test "v1" do
      params = [type: 3]
      {:ok, _command} = AlarmGet.new(params)
    end

    test "v2" do
      params = [type: 0, zwave_type: :home_security]
      {:ok, _command} = AlarmGet.new(params)
    end

    test "v3+" do
      params = [type: 0, zwave_type: :home_security, zwave_event: :intrusion]
      {:ok, _command} = AlarmGet.new(params)
    end
  end

  describe "encodes params correctly" do
    test "v1" do
      params = [type: 3]
      {:ok, command} = AlarmGet.new(params)
      expected_binary = <<0x03>>
      assert expected_binary == AlarmGet.encode_params(command)
    end

    test "v2" do
      params = [type: 0, zwave_type: :home_security]
      {:ok, command} = AlarmGet.new(params)
      expected_binary = <<0x00, 0x07>>
      assert expected_binary == AlarmGet.encode_params(command)
    end

    test "v3+" do
      params = [type: 0, zwave_type: :home_security, zwave_event: :intrusion]
      {:ok, command} = AlarmGet.new(params)
      expected_binary = <<0x00, 0x07, 0x02>>
      assert expected_binary == AlarmGet.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1" do
      binary_params = <<0x03>>
      {:ok, params} = AlarmGet.decode_params(binary_params)
      assert Keyword.get(params, :type) == 3
    end

    test "v2" do
      binary_params = <<0x00, 0x07>>
      {:ok, params} = AlarmGet.decode_params(binary_params)
      assert Keyword.get(params, :type) == 0
      assert Keyword.get(params, :zwave_type) == :home_security
    end

    test "v3+" do
      binary_params = <<0x00, 0x07, 0x02>>
      {:ok, params} = AlarmGet.decode_params(binary_params)
      assert Keyword.get(params, :type) == 0
      assert Keyword.get(params, :zwave_type) == :home_security
      assert Keyword.get(params, :zwave_event) == :intrusion
    end
  end
end
