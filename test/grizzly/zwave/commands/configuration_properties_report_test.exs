defmodule Grizzly.ZWave.Commands.ConfigurationPropertiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationPropertiesReport

  describe "creates the command and validates params" do
    test "v1, size 0" do
      params = [param_number: 2, format: :unsigned_integer, size: 0, next_param_number: 3]
      {:ok, _command} = ConfigurationPropertiesReport.new(params)
    end

    test "v1, size > 0" do
      params = [
        param_number: 2,
        format: :unsigned_integer,
        size: 1,
        min_value: 0,
        max_value: 10,
        default_value: 1,
        next_param_number: 3
      ]

      {:ok, _command} = ConfigurationPropertiesReport.new(params)
    end

    test "v4, size 0" do
      params = [
        param_number: 2,
        read_only: false,
        altering_capabilities: true,
        advanced: true,
        no_bulk_support: false,
        format: :unsigned_integer,
        size: 0,
        next_param_number: 3
      ]

      {:ok, _command} = ConfigurationPropertiesReport.new(params)
    end

    test "v4, size > 0" do
      params = [
        param_number: 2,
        read_only: false,
        altering_capabilities: true,
        advanced: true,
        no_bulk_support: false,
        format: :unsigned_integer,
        size: 1,
        min_value: 0,
        max_value: 10,
        default_value: 1,
        next_param_number: 3
      ]

      {:ok, _command} = ConfigurationPropertiesReport.new(params)
    end
  end

  describe "encodes params correctly" do
    test "v1, size 0" do
      params = [param_number: 2, format: :unsigned_integer, size: 0, next_param_number: 3]
      {:ok, command} = ConfigurationPropertiesReport.new(params)

      expected_params_binary =
        <<0x02::size(16), 0x00::size(2), 0x01::size(3), 0x00::size(3), 0x03::size(16)>>

      assert expected_params_binary == ConfigurationPropertiesReport.encode_params(command)
    end

    test "v1, size > 0" do
      params = [
        param_number: 2,
        format: :signed_integer,
        size: 1,
        min_value: -10,
        max_value: 10,
        default_value: 1,
        next_param_number: 3
      ]

      {:ok, command} = ConfigurationPropertiesReport.new(params)

      expected_params_binary =
        <<0x02::size(16), 0x00::size(2), 0x00::size(3), 0x01::size(3), 0xF6, 0x0A, 0x01,
          0x03::size(16)>>

      assert expected_params_binary == ConfigurationPropertiesReport.encode_params(command)
    end

    test "v4, size 0" do
      params = [
        param_number: 2,
        read_only: false,
        altering_capabilities: true,
        advanced: true,
        no_bulk_support: false,
        format: :unsigned_integer,
        size: 0,
        next_param_number: 3
      ]

      {:ok, command} = ConfigurationPropertiesReport.new(params)

      expected_params_binary =
        <<0x02::size(16), 0x01::size(1), 0x00::size(1), 0x01::size(3), 0x00::size(3),
          0x03::size(16), 0x00::size(6), 0x00::size(1), 0x01::size(1)>>

      assert expected_params_binary == ConfigurationPropertiesReport.encode_params(command)
    end

    test "v4, size > 0" do
      params = [
        param_number: 2,
        read_only: false,
        altering_capabilities: true,
        advanced: true,
        no_bulk_support: false,
        format: :unsigned_integer,
        size: 1,
        min_value: 0,
        max_value: 10,
        default_value: 1,
        next_param_number: 3
      ]

      {:ok, command} = ConfigurationPropertiesReport.new(params)

      expected_params_binary =
        <<0x02::size(16), 0x01::size(1), 0x00::size(1), 0x01::size(3), 0x01::size(3), 0x00, 0x0A,
          0x01, 0x03::size(16), 0x00::size(6), 0x00::size(1), 0x01::size(1)>>

      assert expected_params_binary == ConfigurationPropertiesReport.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1, size 0" do
      params_binary =
        <<0x02::size(16), 0x00::size(2), 0x01::size(3), 0x00::size(3), 0x03::size(16)>>

      {:ok, params} = ConfigurationPropertiesReport.decode_params(params_binary)

      assert Keyword.get(params, :param_number) == 2
      assert Keyword.get(params, :format) == :unsigned_integer
      assert Keyword.get(params, :size) == 0
      assert Keyword.get(params, :next_param_number) == 3
    end

    test "v1, size > 0" do
      params_binary =
        <<0x02::size(16), 0x00::size(2), 0x00::size(3), 0x01::size(3), 0xF6, 0x0A, 0x01,
          0x03::size(16)>>

      {:ok, params} = ConfigurationPropertiesReport.decode_params(params_binary)
      assert Keyword.get(params, :param_number) == 2
      assert Keyword.get(params, :format) == :signed_integer
      assert Keyword.get(params, :size) == 1
      assert Keyword.get(params, :min_value) == -10
      assert Keyword.get(params, :max_value) == 10
      assert Keyword.get(params, :default_value) == 1
      assert Keyword.get(params, :next_param_number) == 3
    end

    test "v4, size 0" do
      params_binary =
        <<0x02::size(16), 0x01::size(1), 0x00::size(1), 0x01::size(3), 0x00::size(3),
          0x03::size(16), 0x00::size(6), 0x00::size(1), 0x01::size(1)>>

      {:ok, params} = ConfigurationPropertiesReport.decode_params(params_binary)
      assert Keyword.get(params, :param_number) == 2
      assert Keyword.get(params, :read_only) == false
      assert Keyword.get(params, :altering_capabilities) == true
      assert Keyword.get(params, :advanced) == true
      assert Keyword.get(params, :no_bulk_support) == false
      assert Keyword.get(params, :format) == :unsigned_integer
      assert Keyword.get(params, :size) == 0
      assert Keyword.get(params, :next_param_number) == 3
    end

    test "v4, size > 0" do
      params_binary =
        <<0x02::size(16), 0x01::size(1), 0x00::size(1), 0x01::size(3), 0x01::size(3), 0x00, 0x0A,
          0x01, 0x03::size(16), 0x00::size(6), 0x00::size(1), 0x01::size(1)>>

      {:ok, params} = ConfigurationPropertiesReport.decode_params(params_binary)
      assert Keyword.get(params, :param_number) == 2
      assert Keyword.get(params, :read_only) == false
      assert Keyword.get(params, :altering_capabilities) == true
      assert Keyword.get(params, :advanced) == true
      assert Keyword.get(params, :no_bulk_support) == false
      assert Keyword.get(params, :format) == :unsigned_integer
      assert Keyword.get(params, :size) == 1
      assert Keyword.get(params, :min_value) == 0
      assert Keyword.get(params, :max_value) == 10
      assert Keyword.get(params, :default_value) == 1
      assert Keyword.get(params, :next_param_number) == 3
    end
  end
end
