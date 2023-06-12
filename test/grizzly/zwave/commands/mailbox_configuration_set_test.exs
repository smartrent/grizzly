defmodule Grizzly.ZWave.Commands.MailboxConfigurationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MailboxConfigurationSet

  test "encodes params correctly" do
    expected_binary = <<2, 253, 0, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 161, 83>>

    {:ok, cmd} =
      MailboxConfigurationSet.new(
        mode: :proxy,
        destination_ipv6_address: {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 2},
        destination_port: 41299
      )

    assert ^expected_binary = MailboxConfigurationSet.encode_params(cmd)
  end

  test "decodes params correctly" do
    {:ok, params} =
      MailboxConfigurationSet.decode_params(
        <<2, 253, 0, 170, 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 161, 83>>
      )

    assert params[:mode] == :proxy
    assert params[:destination_ipv6_address] == {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 2}
    assert params[:destination_port] == 41299
  end
end
