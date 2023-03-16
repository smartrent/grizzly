defmodule Grizzly.ZWave.Commands.ZipNdNodeAdvertisementTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZipNdNodeAdvertisement

  test "creates the command and validates params" do
    assert {:ok, _cmd} =
             ZipNdNodeAdvertisement.new(
               node_id: 500,
               ipv6_address: to_ipv6!("FD00::500"),
               local: true,
               validity: :information_ok,
               home_id: 0xDEADBEEF
             )
  end

  test "encodes params correctly" do
    {:ok, cmd} =
      ZipNdNodeAdvertisement.new(
        node_id: 12,
        ipv6_address: to_ipv6!("FD00::12"),
        local: true,
        validity: :information_ok,
        home_id: 0xDEADBEEF
      )

    expected_binary = <<0::5, 1::1, 0::2, 12::8, 0xFD00::16, 0x0::96, 0x12::16, 0xDEADBEEF::32>>
    assert expected_binary == ZipNdNodeAdvertisement.encode_params(cmd)

    {:ok, cmd} =
      ZipNdNodeAdvertisement.new(
        node_id: 500,
        ipv6_address: to_ipv6!("FD00::1F4"),
        local: false,
        validity: :information_obsolete,
        home_id: 0xDEADBEEF
      )

    expected_binary =
      <<0::5, 0::1, 1::2, 0xFF::8, 0xFD00::16, 0x0::96, 500::16, 0xDEADBEEF::32, 500::16>>

    assert expected_binary == ZipNdNodeAdvertisement.encode_params(cmd)

    {:ok, cmd} =
      ZipNdNodeAdvertisement.new(
        node_id: 0,
        ipv6_address: to_ipv6!("0::0"),
        local: false,
        validity: :information_not_found,
        home_id: 0xDEADBEEF
      )

    expected_binary = <<0::5, 0::1, 2::2, 0::8, 0::128, 0xDEADBEEF::32>>

    assert expected_binary == ZipNdNodeAdvertisement.encode_params(cmd)
  end

  test "decodes params correctly" do
    assert {:ok, params} =
             ZipNdNodeAdvertisement.decode_params(
               <<0::5, 1::1, 0::2, 12::8, 0xFD00::16, 0x0::96, 12::16, 0xDEADBEEF::32>>
             )

    assert params[:node_id] == 12
    assert params[:local] == true
    assert params[:validity] == :information_ok
    assert params[:ipv6_address] == to_ipv6!("FD00::C")
    assert params[:home_id] == 0xDEADBEEF

    assert {:ok, params} =
             ZipNdNodeAdvertisement.decode_params(
               <<0::5, 0::1, 1::2, 0xFF::8, 0xFD00::16, 0x0::96, 500::16, 0xDEADBEEF::32,
                 500::16>>
             )

    assert params[:node_id] == 500
    refute params[:local]
    assert params[:validity] == :information_obsolete
    assert params[:ipv6_address] == to_ipv6!("FD00::1F4")
    assert params[:home_id] == 0xDEADBEEF

    assert {:ok, params} =
             ZipNdNodeAdvertisement.decode_params(
               <<0::5, 0::1, 2::2, 0::8, 0::128, 0xDEADBEEF::32>>
             )

    assert params[:node_id] == 0
    refute params[:local]
    assert params[:validity] == :information_not_found
    assert params[:ipv6_address] == to_ipv6!("0::0")
    assert params[:home_id] == 0xDEADBEEF

    assert {:ok, params} =
             ZipNdNodeAdvertisement.decode_params(
               <<0, 1, 253, 0, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 203, 28, 128, 107, 0,
                 0>>
             )

    assert params[:node_id] == 1
    refute params[:local]
    assert params[:validity] == :information_ok
    assert params[:ipv6_address] == to_ipv6!("FD00:AAAA::1")
    assert params[:home_id] == 0xCB1C806B
  end

  defp to_ipv6!(addr) when is_binary(addr),
    do: addr |> :erlang.binary_to_list() |> to_ipv6!()

  defp to_ipv6!(addr) do
    case :inet.parse_ipv6_address(addr) do
      {:ok, r} -> r
      _ -> raise "Failed to parse IPv6 address: #{inspect(addr)}"
    end
  end
end
