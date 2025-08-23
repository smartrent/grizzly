defmodule Grizzly.ZWave.Commands.ZwaveplusInfoReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ZwaveplusInfoReport

  test "creates the command and validates params" do
    params = [
      zwaveplus_version: 2,
      role_type: :central_static_controller,
      node_type: :zwaveplus_node,
      installer_icon_type: 0x0100,
      user_icon_type: 0x0500
    ]

    {:ok, _command} = ZwaveplusInfoReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      zwaveplus_version: 2,
      role_type: :central_static_controller,
      node_type: :zwaveplus_node,
      installer_icon_type: 0x0100,
      user_icon_type: 0x0500
    ]

    {:ok, command} = ZwaveplusInfoReport.new(params)

    expected_binary = <<0x02, 0x00, 0x00, 0x0100::16, 0x0500::16>>
    assert expected_binary == ZwaveplusInfoReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x02, 0x00, 0x00, 0x0100::16, 0x0500::16>>

    {:ok, params} = ZwaveplusInfoReport.decode_params(binary_params)
    assert Keyword.get(params, :zwaveplus_version) == 2
    assert Keyword.get(params, :role_type) == :central_static_controller
    assert Keyword.get(params, :node_type) == :zwaveplus_node
    assert Keyword.get(params, :installer_icon_type) == 0x0100
    assert Keyword.get(params, :user_icon_type) == 0x0500
  end
end
