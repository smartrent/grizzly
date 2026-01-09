defmodule Grizzly.ZWave.Commands.AntitheftReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AntitheftReport

  test "creates the command and validates params" do
    params = [
      status: :protection_disabled_unlocked,
      manufacturer_id: 126,
      antitheft_hint: "rabbit",
      locking_entity_id: 341
    ]

    {:ok, _command} = Commands.create(:antitheft_report, params)
  end

  test "encodes params correctly" do
    hint = "rabbit"

    params = [
      status: :protection_disabled_unlocked,
      manufacturer_id: 126,
      antitheft_hint: "rabbit",
      locking_entity_id: 341
    ]

    {:ok, command} = Commands.create(:antitheft_report, params)
    expected_binary = <<0x01, 126::16, 6>> <> hint <> <<341::16>>
    assert expected_binary == AntitheftReport.encode_params(command)
  end

  test "decodes params correctly" do
    hint = "rabbit"
    params_binary = <<0x01, 126::16, 6>> <> hint <> <<341::16>>
    {:ok, params} = AntitheftReport.decode_params(params_binary)
    assert Keyword.get(params, :status) == :protection_disabled_unlocked
    assert Keyword.get(params, :manufacturer_id) == 126
    assert Keyword.get(params, :antitheft_hint) == hint
    assert Keyword.get(params, :locking_entity_id) == 341
  end
end
