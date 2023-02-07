defmodule Grizzly.ZWave.Commands.UserCodeChecksumReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.UserCodeChecksumReport

  test "creates the command and validates params" do
    assert {:ok, _} = UserCodeChecksumReport.new(checksum: 0xEAAD)
  end

  test "encodes params correctly" do
    {:ok, command} = UserCodeChecksumReport.new(checksum: 0xEAAD)
    assert <<0xEA, 0xAD>> == UserCodeChecksumReport.encode_params(command)
  end

  test "decodes params correctly" do
    assert {:ok, [checksum: 0xEAAD]} == UserCodeChecksumReport.decode_params(<<0xEA, 0xAD>>)
  end
end
