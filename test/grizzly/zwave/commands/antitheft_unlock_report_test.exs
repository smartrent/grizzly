defmodule Grizzly.ZWave.Commands.AntitheftUnlockReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AntitheftUnlockReport

  test "creates the command and validates params" do
    params = [
      state: :unlocked,
      restricted: false,
      manufacturer_id: 260,
      antitheft_hint: "rabbit",
      locking_entity_id: 222
    ]

    {:ok, _command} = AntitheftUnlockReport.new(params)
  end

  test "encodes params correctly" do
    hint = "rabbit"

    params = [
      state: :unlocked,
      restricted: false,
      manufacturer_id: 260,
      antitheft_hint: hint,
      locking_entity_id: 222
    ]

    {:ok, command} = AntitheftUnlockReport.new(params)

    expected_params_binary =
      <<0x00::2, 0x06::4, 0x00::1, 0x00::1>> <>
        hint <>
        <<260::16, 222::16>>

    assert expected_params_binary == AntitheftUnlockReport.encode_params(command)
  end

  test "decodes params correctly" do
    hint = "rabbit"

    params_binary =
      <<0x00::2, 0x06::4, 0x00::1, 0x00::1>> <>
        hint <>
        <<260::16, 222::16>>

    {:ok, params} = AntitheftUnlockReport.decode_params(params_binary)
    assert Keyword.get(params, :state) == :unlocked
    assert Keyword.get(params, :restricted) == false
    assert Keyword.get(params, :manufacturer_id) == 260
    assert Keyword.get(params, :antitheft_hint) == hint
    assert Keyword.get(params, :locking_entity_id) == 222
  end
end
