defmodule Grizzly.ZWave.Commands.CommandClassReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.CommandClassReport
  alias Grizzly.ZWave.CommandClasses.Version

  test "creates the command and validates params" do
    assert {:ok,
            %Command{
              name: :command_class_report,
              command_byte: 0x14,
              command_class: Version,
              impl: CommandClassReport
            }} = CommandClassReport.new(command_class: :switch_binary, version: 2)
  end

  test "encodes params correctly" do
    {:ok, command} = CommandClassReport.new(command_class: :switch_binary, version: 2)
    expected_binary = <<0x25, 0x02>>
    assert expected_binary == CommandClassReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x25, 0x02>>
    {:ok, params} = CommandClassReport.decode_params(binary_params)

    assert Keyword.get(params, :command_class) == :switch_binary
    assert Keyword.get(params, :version) == 2
  end
end
