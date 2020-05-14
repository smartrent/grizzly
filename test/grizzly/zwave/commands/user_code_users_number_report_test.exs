defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.UserCodeUsersNumberReport

  test "creates the command and validates params" do
    params = [supported_users: 24]
    {:ok, _command} = UserCodeUsersNumberReport.new(params)
  end

  test "encodes params correctly" do
    params = [supported_users: 24]
    {:ok, command} = UserCodeUsersNumberReport.new(params)

    expected_binary = <<0x18>>

    assert expected_binary == UserCodeUsersNumberReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x18>>

    {:ok, params} = UserCodeUsersNumberReport.decode_params(binary_params)
    assert Keyword.get(params, :supported_users) == 24
  end
end
