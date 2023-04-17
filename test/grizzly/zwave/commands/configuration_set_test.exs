defmodule Grizzly.ZWave.Commands.ConfigurationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ConfigurationSet

  describe "creates the command and validates params" do
    test "with default" do
      assert {:ok, _configuration_set} = ConfigurationSet.new(value: :default, param_number: 15)
    end

    test "with a value" do
      assert {:ok, _configuration_set} =
               ConfigurationSet.new(value: 123, param_number: 15, size: 1)
    end
  end

  describe "encodes params correctly with format signed_integer" do
    test "when default is set" do
      {:ok, configuration_set} = ConfigurationSet.new(value: :default, param_number: 15)

      assert <<0x0F, 0x81, 0x00>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 1 byte neg value is set - default signed_integer format" do
      {:ok, configuration_set} = ConfigurationSet.new(value: -126, param_number: 15, size: 1)
      assert <<0x0F, 0x01, 0x82>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 1 byte neg value is set" do
      {:ok, configuration_set} =
        ConfigurationSet.new(value: -126, param_number: 15, size: 1, format: :signed_integer)

      assert <<0x0F, 0x01, 0x82>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 1 byte pos value is set" do
      {:ok, configuration_set} =
        ConfigurationSet.new(value: 115, param_number: 15, size: 1, format: :signed_integer)

      assert <<0x0F, 0x01, 0x73>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 2 byte neg value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: -14313, param_number: 15, size: 2, format: :signed_integer)

      assert <<0x0F, 0x02, 0xC8, 0x17>> == ConfigurationSet.encode_params(command)
    end

    test "when a 2 byte pos value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 29463, param_number: 15, size: 2, format: :signed_integer)

      assert <<0x0F, 0x02, 0x73, 0x17>> == ConfigurationSet.encode_params(command)
    end

    test "when a 4 byte neg value is set" do
      {:ok, command} =
        ConfigurationSet.new(
          value: -3_664_127,
          param_number: 15,
          size: 4,
          format: :signed_integer
        )

      assert <<0x0F, 0x04, 0xFF, 0xC8, 0x17, 0x01>> == ConfigurationSet.encode_params(command)
    end

    test "when a 4 byte pos value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 7_542_529, param_number: 15, size: 4, format: :signed_integer)

      assert <<0x0F, 0x04, 0x00, 0x73, 0x17, 0x01>> == ConfigurationSet.encode_params(command)
    end

    test "when an illegal 3 byte value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 7_542_529, param_number: 15, size: 3, format: :signed_integer)

      assert %ArgumentError{
               __exception__: true,
               message:
                 "Invalid parameter. 7542529 with format :signed_integer will not fit in 3 bytes"
             } ==
               catch_error(ConfigurationSet.encode_params(command))
    end

    test "when an out-of-range byte value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 128, param_number: 15, size: 1, format: :signed_integer)

      assert %ArgumentError{
               __exception__: true,
               message:
                 "Invalid parameter. 128 with format :signed_integer will not fit in 1 bytes"
             } ==
               catch_error(ConfigurationSet.encode_params(command))
    end
  end

  describe "encodes params correctly with format unsigned_integer" do
    test "when a 1 byte neg value is set - default signed_integer format" do
      {:ok, configuration_set} = ConfigurationSet.new(value: -126, param_number: 15, size: 1)
      assert <<0x0F, 0x01, 0x82>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 1 byte neg value is set" do
      {:ok, configuration_set} =
        ConfigurationSet.new(value: 128, param_number: 15, size: 1, format: :unsigned_integer)

      assert <<0x0F, 0x01, 0x80>> == ConfigurationSet.encode_params(configuration_set)
    end

    test "when a 2 byte pos value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 60000, param_number: 15, size: 2, format: :unsigned_integer)

      assert <<0x0F, 0x02, 0xEA, 0x60>> == ConfigurationSet.encode_params(command)
    end

    test "when a 4 byte neg value is set" do
      {:ok, command} =
        ConfigurationSet.new(
          value: 4_294_967_295,
          param_number: 15,
          size: 4,
          format: :unsigned_integer
        )

      assert <<0x0F, 0x04, 0xFF, 0xFF, 0xFF, 0xFF>> == ConfigurationSet.encode_params(command)
    end

    test "when an illegal 3 byte value is set" do
      {:ok, command} =
        ConfigurationSet.new(
          value: 4_294_967_296,
          param_number: 15,
          size: 3,
          format: :unsigned_integer
        )

      assert %ArgumentError{
               __exception__: true,
               message:
                 "Invalid parameter. 4294967296 with format :unsigned_integer will not fit in 3 bytes"
             } ==
               catch_error(ConfigurationSet.encode_params(command))
    end

    test "when an out-of-range byte value is set" do
      {:ok, command} =
        ConfigurationSet.new(value: 256, param_number: 15, size: 1, format: :unsigned_integer)

      assert %ArgumentError{
               __exception__: true,
               message:
                 "Invalid parameter. 256 with format :unsigned_integer will not fit in 1 bytes"
             } ==
               catch_error(ConfigurationSet.encode_params(command))
    end
  end

  describe "decodes params correctly" do
    test "when default flag is set" do
      binary = <<0x0F, 0x80, 0x00>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == :default
    end

    test "when 1 byte pos value" do
      binary = <<0x0F, 0x01, 0x01>>

      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 0x01
    end

    test "when 1 byte neg value" do
      binary = <<0x0F, 0x01, 0x82>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -126
    end

    test "when 2 byte pos value" do
      binary = <<0x0F, 0x02, 0x73, 0x17>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 29463
    end

    test "when 2 byte net value" do
      binary = <<0x0F, 0x02, 0xC8, 0x17>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -14313
    end

    test "when 3 byte pos value" do
      binary = <<0x0F, 0x03, 0x73, 0x17, 0x01>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 7_542_529
    end

    test "when 3 byte neg value" do
      binary = <<0x0F, 0x03, 0xC8, 0x17, 0x01>>
      assert {:ok, params} = ConfigurationSet.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -3_664_127
    end
  end
end
