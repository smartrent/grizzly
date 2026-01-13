defmodule Grizzly.ZWave.Commands.CentralSceneSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CentralSceneSupportedReport

  test "creates the command and validates params" do
    params = [
      supported_scenes: 2,
      slow_refresh_support: true,
      identical: true,
      bit_mask_bytes: 1,
      supported_key_attributes: [
        [
          :key_pressed_1_time,
          :key_released,
          :key_held_down,
          :key_pressed_2_times
        ]
      ]
    ]

    {:ok, _command} = Commands.create(:central_scene_supported_report, params)
  end

  describe "encodes params correctly" do
    test "not identical" do
      params = [
        supported_scenes: 2,
        slow_refresh_support: true,
        identical: false,
        bit_mask_bytes: 1,
        supported_key_attributes: [
          [
            :key_pressed_1_time,
            :key_released,
            :key_held_down,
            :key_pressed_2_times
          ],
          [:key_pressed_1_time]
        ]
      ]

      {:ok, command} = Commands.create(:central_scene_supported_report, params)

      expected_params_binary =
        <<0x02, 0x01::1, 0x00::4, 0x01::2, 0x00::1, 0b00001111, 0b00000001>>

      assert expected_params_binary == CentralSceneSupportedReport.encode_params(nil, command)
    end

    test "identical" do
      params = [
        supported_scenes: 2,
        slow_refresh_support: true,
        identical: true,
        bit_mask_bytes: 1,
        supported_key_attributes: [
          [
            :key_pressed_1_time,
            :key_released,
            :key_held_down,
            :key_pressed_2_times
          ]
        ]
      ]

      {:ok, command} = Commands.create(:central_scene_supported_report, params)

      expected_params_binary =
        <<0x02, 0x01::1, 0x00::4, 0x01::2, 0x01::1, 0b00001111>>

      assert expected_params_binary == CentralSceneSupportedReport.encode_params(nil, command)
    end
  end

  describe "decodes params correctly" do
    test "not identical" do
      params_binary =
        <<0x02, 0x01::1, 0x00::4, 0x01::2, 0x00::1, 0b00001111, 0b00000001>>

      {:ok, params} = CentralSceneSupportedReport.decode_params(nil, params_binary)
      assert Keyword.get(params, :supported_scenes) == 2
      assert Keyword.get(params, :slow_refresh_support) == true
      assert Keyword.get(params, :identical) == false
      assert Keyword.get(params, :bit_mask_bytes) == 1
      supported_attribute_keys = Keyword.get(params, :supported_key_attributes)

      assert Enum.sort(Enum.at(supported_attribute_keys, 0)) ==
               Enum.sort([
                 :key_pressed_1_time,
                 :key_released,
                 :key_held_down,
                 :key_pressed_2_times
               ])

      assert Enum.at(supported_attribute_keys, 1) == [:key_pressed_1_time]
    end

    test "identical" do
      params_binary =
        <<0x02, 0x01::1, 0x00::4, 0x01::2, 0x01::1, 0b00000001>>

      {:ok, params} = CentralSceneSupportedReport.decode_params(nil, params_binary)
      assert Keyword.get(params, :supported_scenes) == 2
      assert Keyword.get(params, :slow_refresh_support) == true
      assert Keyword.get(params, :identical) == true
      assert Keyword.get(params, :bit_mask_bytes) == 1
      assert Keyword.get(params, :supported_key_attributes) == [[:key_pressed_1_time]]
    end

    test "identical and superfluous" do
      params_binary = <<2, 3, 31, 0, 0, 0>>

      {:ok, params} = CentralSceneSupportedReport.decode_params(nil, params_binary)

      assert Keyword.get(params, :supported_scenes) == 2
      assert Keyword.get(params, :slow_refresh_support) == false
      assert Keyword.get(params, :identical) == true
      assert Keyword.get(params, :bit_mask_bytes) == 1

      assert Keyword.get(params, :supported_key_attributes) == [
               [
                 :key_pressed_3_times,
                 :key_pressed_2_times,
                 :key_held_down,
                 :key_released,
                 :key_pressed_1_time
               ]
             ]
    end
  end
end
