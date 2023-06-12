defmodule Grizzly.ZWave.Commands.MailboxConfigurationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MailboxConfigurationReport

  test "encodes params correctly" do
    expected_binary =
      <<26, 7, 208, 253, 0, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 161, 83>>

    {:ok, cmd} =
      MailboxConfigurationReport.new(
        mode: :proxy,
        supported_modes: [:proxy, :service],
        capacity: 2000,
        destination_ipv6_address: {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 2},
        destination_port: 41299
      )

    assert ^expected_binary = MailboxConfigurationReport.encode_params(cmd)
  end

  test "decodes params correctly" do
    {:ok, params} =
      MailboxConfigurationReport.decode_params(
        <<26, 7, 208, 253, 0, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 161, 83>>
      )

    assert params[:mode] == :proxy
    assert params[:supported_modes] == [:service, :proxy]
    assert params[:capacity] == 2000
    assert params[:destination_ipv6_address] == {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 2}
    assert params[:destination_port] == 41299
  end
end
