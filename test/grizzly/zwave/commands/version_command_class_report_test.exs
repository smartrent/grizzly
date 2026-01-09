defmodule Grizzly.ZWave.Commands.VersionCommandClassReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Version
  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.VersionCommandClassReport

  test "creates the command and validates params" do
    assert {:ok,
            %Command{
              name: :version_command_class_report,
              command_byte: 0x14,
              command_class: Version
            }} =
             Commands.create(:version_command_class_report,
               command_class: :switch_binary,
               version: 2
             )
  end

  test "encodes params correctly" do
    {:ok, command} =
      Commands.create(:version_command_class_report, command_class: :switch_binary, version: 2)

    expected_binary = <<0x25, 0x02>>
    assert expected_binary == VersionCommandClassReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x25, 0x02>>
    {:ok, params} = VersionCommandClassReport.decode_params(binary_params)

    assert Keyword.get(params, :command_class) == :switch_binary
    assert Keyword.get(params, :version) == 2
  end
end
