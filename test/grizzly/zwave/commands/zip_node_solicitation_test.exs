defmodule Grizzly.ZWave.Commands.ZipNodeSolicitationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipNodeSolicitation

  test "creates the command and validates params" do
    params = [ipv6_address: "0306:0709:0803:0405:0708:0905:0607:0809"]

    {:ok, _command} = ZipNodeSolicitation.new(params)
  end

  test "encodes params correctly" do
    params = [ipv6_address: "0306:0709:0803:0405:0708:0905:0607:0809"]

    {:ok, command} = ZipNodeSolicitation.new(params)

    expected_binary = <<0x00, 0x00>> <> <<3, 6, 7, 9, 8, 3, 4, 5, 7, 8, 9, 5, 6, 7, 8, 9>>

    assert expected_binary == ZipNodeSolicitation.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x00, 0x00>> <> <<3, 6, 7, 9, 8, 3, 4, 5, 7, 8, 9, 5, 6, 7, 8, 9>>

    {:ok, params} = ZipNodeSolicitation.decode_params(binary_params)
    assert Keyword.get(params, :ipv6_address) == "0306:0709:0803:0405:0708:0905:0607:0809"
  end
end
