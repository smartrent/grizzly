defmodule Grizzly.ZWave.Commands.AlarmEventSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AlarmEventSupportedReport

  test "creates the command and validates params" do
    params = [
      type: :access_control,
      events: [
        :manual_lock_operation,
        :manual_unlock_operation,
        :rf_lock_operation,
        :rf_unlock_operation,
        :keypad_lock_operation,
        :keypad_unlock_operation,
        :lock_jammed
      ]
    ]

    {:ok, _command} = AlarmEventSupportedReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      type: :access_control,
      events: [
        :manual_lock_operation,
        :manual_unlock_operation,
        :rf_lock_operation,
        :rf_unlock_operation,
        :keypad_lock_operation,
        :keypad_unlock_operation,
        :lock_jammed
      ]
    ]

    {:ok, command} = AlarmEventSupportedReport.new(params)
    expected_binary = <<0x06, 0x00::size(3), 0x02::size(5), 0b01111110, 0b00001000>>
    assert expected_binary == AlarmEventSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0x06, 0x00::size(3), 0x02::size(5), 0b01111110, 0b00001000>>
    {:ok, params} = AlarmEventSupportedReport.decode_params(binary_params)
    assert :access_control == Keyword.get(params, :type)

    assert Enum.sort([
             :manual_lock_operation,
             :manual_unlock_operation,
             :rf_lock_operation,
             :rf_unlock_operation,
             :keypad_lock_operation,
             :keypad_unlock_operation,
             :lock_jammed
           ]) ==
             Enum.sort(Keyword.get(params, :events))
  end
end
