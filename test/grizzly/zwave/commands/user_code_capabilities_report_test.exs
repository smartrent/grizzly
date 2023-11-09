defmodule Grizzly.ZWave.Commands.UserCodeCapabilitiesReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.{Command, Commands.UserCodeCapabilitiesReport}

  test "creates the command and validates params" do
    assert {:ok, %Command{}} = UserCodeCapabilitiesReport.new([])
  end

  test "encodes params correctly" do
    params = [
      admin_code_supported?: true,
      admin_code_deactivation_supported?: true,
      user_code_checksum_supported?: true,
      multi_user_code_report_supported?: false,
      multi_user_code_set_supported?: false,
      supported_user_id_statuses: [:available, :occupied],
      supported_keypad_modes: [:normal, :privacy],
      supported_keypad_keys: ~c"()*+,-./014567"
    ]

    binary =
      params
      |> UserCodeCapabilitiesReport.new()
      |> elem(1)
      |> UserCodeCapabilitiesReport.encode_params()

    expected_binary =
      <<1::1, 1::1, 0::1, 1::5, 0b0011::8, 1::1, 0::1, 0::1, 1::5, 0b0101::8, 0::3, 7::5, 0b0,
        0b0, 0b0, 0b0, 0b0, 0b11111111, 0b11110011>>

    assert binary == expected_binary
  end

  test "decodes params correctly" do
    input =
      <<1::1, 1::1, 0::1, 1::5, 0b11010::8, 1::1, 0::1, 0::1, 1::5, 0b0101::8, 0::3, 7::5, 0b0,
        0b0, 0b0, 0b0, 0b0, 0b11111111, 0b11110011>>

    {:ok, params} = UserCodeCapabilitiesReport.decode_params(input)

    assert params[:admin_code_supported?]
    assert params[:admin_code_deactivation_supported?]
    assert params[:user_code_checksum_supported?]
    refute params[:multi_user_code_report_supported?]
    refute params[:multi_user_code_set_supported?]

    refute :available in params[:supported_user_id_statuses]
    refute :disabled in params[:supported_user_id_statuses]
    assert :messaging in params[:supported_user_id_statuses]
    assert :occupied in params[:supported_user_id_statuses]
    assert :passage in params[:supported_user_id_statuses]
    refute :unknown in params[:supported_user_id_statuses]

    assert :normal in params[:supported_keypad_modes]
    refute :vacation in params[:supported_keypad_modes]
    assert :privacy in params[:supported_keypad_modes]
    refute :lockout in params[:supported_keypad_modes]
    refute :unknown in params[:supported_keypad_modes]

    assert params[:supported_keypad_keys] == ~c"()*+,-./014567"
  end

  test "decodes params from a real device" do
    {:ok, params} =
      UserCodeCapabilitiesReport.decode_params(
        <<0x81, 0x0F, 0x01, 0x07, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x03>>
      )

    assert params[:admin_code_supported?]
    refute params[:admin_code_deactivation_supported?]
    refute params[:user_code_checksum_supported?]
    refute params[:multi_user_code_report_supported?]
    refute params[:multi_user_code_set_supported?]

    assert :available in params[:supported_user_id_statuses]
    assert :disabled in params[:supported_user_id_statuses]
    assert :messaging in params[:supported_user_id_statuses]
    assert :occupied in params[:supported_user_id_statuses]
    refute :passage in params[:supported_user_id_statuses]

    assert :normal in params[:supported_keypad_modes]
    assert :vacation in params[:supported_keypad_modes]
    assert :privacy in params[:supported_keypad_modes]
    refute :lockout in params[:supported_keypad_modes]

    assert params[:supported_keypad_keys] == ~c"0123456789"
  end
end
