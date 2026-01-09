defmodule Grizzly.ZWave.Commands.ConfigurationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.ConfigurationReport

  describe "creates the command and validates params" do
    test "with a value" do
      assert {:ok, _command} =
               Commands.create(:configuration_report, value: 123, param_number: 15, size: 1)
    end
  end

  describe "encodes params correctly" do
    test "when a 1 byte neg value is set" do
      {:ok, configuration_set} =
        Commands.create(:configuration_report, value: -126, param_number: 15, size: 1)

      assert <<0x0F, 0x01, 0x82>> == ConfigurationReport.encode_params(configuration_set)
    end

    test "when a 1 byte pos value is set" do
      {:ok, configuration_set} =
        Commands.create(:configuration_report, value: 115, param_number: 15, size: 1)

      assert <<0x0F, 0x01, 0x73>> == ConfigurationReport.encode_params(configuration_set)
    end

    test "when a 2 byte neg value is set" do
      {:ok, command} =
        Commands.create(:configuration_report, value: -14313, param_number: 15, size: 2)

      assert <<0x0F, 0x02, 0xC8, 0x17>> == ConfigurationReport.encode_params(command)
    end

    test "when a 2 byte pos value is set" do
      {:ok, command} =
        Commands.create(:configuration_report, value: 29463, param_number: 15, size: 2)

      assert <<0x0F, 0x02, 0x73, 0x17>> == ConfigurationReport.encode_params(command)
    end

    test "when a 3 byte neg value is set" do
      {:ok, command} =
        Commands.create(:configuration_report, value: -3_664_127, param_number: 15, size: 3)

      assert <<0x0F, 0x03, 0xC8, 0x17, 0x01>> == ConfigurationReport.encode_params(command)
    end

    test "when a 3 byte pos value is set" do
      {:ok, command} =
        Commands.create(:configuration_report, value: 7_542_529, param_number: 15, size: 3)

      assert <<0x0F, 0x03, 0x73, 0x17, 0x01>> == ConfigurationReport.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "when 1 byte pos value" do
      binary = <<0x0F, 0x01, 0x01>>

      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 0x01
    end

    test "when 1 byte neg value" do
      binary = <<0x0F, 0x01, 0x82>>
      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -126
    end

    test "when 2 byte pos value" do
      binary = <<0x0F, 0x02, 0x73, 0x17>>
      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 29463
    end

    test "when 2 byte net value" do
      binary = <<0x0F, 0x02, 0xC8, 0x17>>
      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -14313
    end

    test "when 3 byte pos value" do
      binary = <<0x0F, 0x03, 0x73, 0x17, 0x01>>
      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == 7_542_529
    end

    test "when 3 byte neg value" do
      binary = <<0x0F, 0x03, 0xC8, 0x17, 0x01>>
      assert {:ok, params} = ConfigurationReport.decode_params(binary)

      assert Keyword.fetch!(params, :value) == -3_664_127
    end
  end
end
