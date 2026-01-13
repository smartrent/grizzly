defmodule Grizzly.ZWave.Commands.AntitheftSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.AntitheftSet

  describe "creates the command and validates params" do
    test "v2" do
      params = [
        state: :locked,
        magic_code: "hocuspocus",
        manufacturer_id: 126,
        antitheft_hint: "rabbit"
      ]

      {:ok, _command} = Commands.create(:antitheft_set, params)
    end

    test "v3" do
      params = [
        state: :locked,
        magic_code: "hocuspocus",
        manufacturer_id: 126,
        antitheft_hint: "rabbit",
        locking_entity_id: 341
      ]

      {:ok, _command} = Commands.create(:antitheft_set, params)
    end
  end

  describe "encodes params correctly" do
    test "v2" do
      magic_code = "hocuspocus"
      hint = "rabbit"

      params = [
        state: :locked,
        magic_code: magic_code,
        manufacturer_id: 126,
        antitheft_hint: hint
      ]

      {:ok, command} = Commands.create(:antitheft_set, params)

      expected_binary =
        <<0x01::1, 10::7>> <>
          magic_code <>
          <<126::16, 6>> <> hint

      assert expected_binary == AntitheftSet.encode_params(nil, command)
    end

    test "v3" do
      magic_code = "hocuspocus"
      hint = "rabbit"

      params = [
        state: :locked,
        magic_code: magic_code,
        manufacturer_id: 126,
        antitheft_hint: hint,
        locking_entity_id: 341
      ]

      {:ok, command} = Commands.create(:antitheft_set, params)

      expected_binary =
        <<0x01::1, 10::7>> <>
          magic_code <>
          <<126::16, 6>> <> hint <> <<341::16>>

      assert expected_binary == AntitheftSet.encode_params(nil, command)
    end
  end

  describe "decodes params correctly" do
    test "v2" do
      magic_code = "hocuspocus"
      hint = "rabbit"

      params_binary =
        <<0x01::1, 10::7>> <>
          magic_code <>
          <<126::16, 6>> <> hint

      {:ok, params} = AntitheftSet.decode_params(nil, params_binary)
      assert Keyword.get(params, :state) == :locked
      assert Keyword.get(params, :magic_code) == magic_code
      assert Keyword.get(params, :manufacturer_id) == 126
      assert Keyword.get(params, :antitheft_hint) == hint
    end

    test "v3" do
      magic_code = "hocuspocus"
      hint = "rabbit"

      params_binary =
        <<0x01::1, 10::7>> <>
          magic_code <>
          <<126::16, 6>> <> hint <> <<341::16>>

      {:ok, params} = AntitheftSet.decode_params(nil, params_binary)
      assert Keyword.get(params, :state) == :locked
      assert Keyword.get(params, :magic_code) == magic_code
      assert Keyword.get(params, :manufacturer_id) == 126
      assert Keyword.get(params, :antitheft_hint) == hint
      assert Keyword.get(params, :locking_entity_id) == 341
    end
  end
end
