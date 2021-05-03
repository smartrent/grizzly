defmodule Grizzly.ZWave.Commands.ZipNodeAdvertisementTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipNodeAdvertisement

  test "creates the command and validates params" do
    params = [
      node_id: 2,
      local: true,
      validity: :information_ok,
      ipv6_address: "0306:0709:0803:0405:0708:0905:0607:0809",
      home_id: 100
    ]

    {:ok, _command} = ZipNodeAdvertisement.new(params)
  end

  test "encodes params correctly" do
    params = [
      node_id: 2,
      local: true,
      validity: :information_ok,
      ipv6_address: "0306:0709:0803:0405:0708:0905:0607:0809",
      home_id: 100
    ]

    {:ok, command} = ZipNodeAdvertisement.new(params)

    expected_binary =
      <<0x00::size(5), 0x01::size(1), 0x00::size(2), 0x02>> <>
        <<3, 6, 7, 9, 8, 3, 4, 5, 7, 8, 9, 5, 6, 7, 8, 9>> <>
        <<100::integer-unsigned-size(4)-unit(8)>>

    assert expected_binary == ZipNodeAdvertisement.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x00::size(5), 0x01::size(1), 0x00::size(2), 0x02>> <>
        <<3, 6, 7, 9, 8, 3, 4, 5, 7, 8, 9, 5, 6, 7, 8, 9>> <>
        <<100::integer-unsigned-size(4)-unit(8)>>

    {:ok, params} = ZipNodeAdvertisement.decode_params(binary_params)
    assert Keyword.get(params, :node_id) == 2
    assert Keyword.get(params, :local) == true
    assert Keyword.get(params, :validity) == :information_ok
    assert Keyword.get(params, :ipv6_address) == "0306:0709:0803:0405:0708:0905:0607:0809"
    assert Keyword.get(params, :home_id) == 100
  end
end
