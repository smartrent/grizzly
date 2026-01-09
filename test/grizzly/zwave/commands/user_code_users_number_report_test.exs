defmodule Grizzly.ZWave.Commands.UserCodeUsersNumberReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserCodeUsersNumberReport

  # V1

  describe "creates the command and validates params" do
    test "v1" do
      params = [supported_users: 24]
      {:ok, _command} = Commands.create(:user_code_users_number_report, params)
    end

    test "v2" do
      params = [supported_users: 24, extended_supported_users: 24]
      {:ok, _command} = Commands.create(:user_code_users_number_report, params)
    end
  end

  describe "encodes params correctly" do
    test "v1" do
      params = [supported_users: 24]
      {:ok, command} = Commands.create(:user_code_users_number_report, params)

      expected_binary = <<0x18>>

      assert expected_binary == UserCodeUsersNumberReport.encode_params(command)
    end

    test "v2" do
      params = [supported_users: 24, extended_supported_users: 24]
      {:ok, command} = Commands.create(:user_code_users_number_report, params)

      expected_binary = <<0x18, 0x00, 0x18>>

      assert expected_binary == UserCodeUsersNumberReport.encode_params(command)
    end
  end

  describe "decodes params correctly" do
    test "v1" do
      binary_params = <<0x18>>

      {:ok, params} = UserCodeUsersNumberReport.decode_params(binary_params)
      assert Keyword.get(params, :supported_users) == 24
    end

    test "v2" do
      binary_params = <<0x18, 0x00, 0x18>>

      {:ok, params} = UserCodeUsersNumberReport.decode_params(binary_params)
      assert Keyword.get(params, :supported_users) == 24
      assert Keyword.get(params, :extended_supported_users) == 24
    end
  end
end
