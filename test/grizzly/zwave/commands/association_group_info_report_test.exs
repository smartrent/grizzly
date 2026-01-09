defmodule Grizzly.ZWave.Commands.AssociationGroupInfoReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AssociationGroupInfoReport

  test "creates the command and validates params" do
    params = [
      dynamic: false,
      group_info: [
        [group_id: 1, profile: :general_lifeline],
        [group_id: 2, profile: :control_key_1]
      ]
    ]

    {:ok, _command} = Commands.create(:association_group_info_report, params)
  end

  test "encodes params correctly" do
    params = [
      dynamic: false,
      groups_info: [
        [group_id: 1, profile: :general_lifeline],
        [group_id: 2, profile: :control_key_1]
      ]
    ]

    {:ok, command} = Commands.create(:association_group_info_report, params)

    expected_binary =
      <<0x01::1, 0x00::1, 0x02::6, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x20,
        0x01, 0x00, 0x00, 0x00>>

    assert expected_binary == AssociationGroupInfoReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params =
      <<0x01::1, 0x00::1, 0x02::6, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x20,
        0x01, 0x00, 0x00, 0x00>>

    {:ok, params} = AssociationGroupInfoReport.decode_params(binary_params)
    assert Keyword.get(params, :dynamic) == false
    [group_1_info, group_2_info] = Keyword.get(params, :groups_info)
    assert Keyword.get(group_1_info, :group_id) == 1
    assert Keyword.get(group_1_info, :profile) == :general_lifeline
    assert Keyword.get(group_2_info, :group_id) == 2
    assert Keyword.get(group_2_info, :profile) == :control_key_1
  end
end
