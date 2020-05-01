defmodule Grizzly.ZWave.Notifications do
  defmodule Generate do
    @moduledoc false
    @table [
      # {type_byte, type, event_byte, event}
      # Smoke Alarm (0x01)
      {0x01, :smoke_alarm, 0x00, :state_idle},
      {0x01, :smoke_alarm, 0x01, :smoke_detected_location_provided},
      {0x01, :smoke_alarm, 0x02, :smoked_detected},
      {0x01, :smoke_alarm, 0x03, :smoke_alarm_test},
      {0x01, :smoke_alarm, 0x04, :replacement_required},
      {0x01, :smoke_alarm, 0x05, :replacement_required_end_of_life},
      {0x01, :smoke_alarm, 0x06, :alarm_silenced},
      {0x01, :smoke_alarm, 0x07, :maintenance_required_planned_periodic_inspection},
      {0x01, :smoke_alarm, 0x08, :maintenance_required_dust_in_device},
      # Access Control (0x06)
      {0x06, :access_control, 0x00, :state_idle},
      {0x06, :access_control, 0x01, :manual_lock_operation},
      {0x06, :access_control, 0x02, :manual_unlock_operation},
      {0x06, :access_control, 0x03, :rf_lock_operation},
      {0x06, :access_control, 0x04, :rf_unlock_operation}
    ]

    defmacro __before_compile__(_) do
      type_to_byte =
        for {alarm_type_byte, alarm_type_name, _, _} <-
              Enum.uniq_by(@table, fn {_, type, _, _} -> type end) do
          quote do
            def type_to_byte(unquote(alarm_type_name)), do: unquote(alarm_type_byte)
          end
        end

      event_to_byte =
        for {_alarm_type_byte, alarm_type_name, alarm_event_byte, alarm_event_name} <- @table do
          quote do
            def event_to_byte(unquote(alarm_type_name), unquote(alarm_event_name)) do
              unquote(alarm_event_byte)
            end
          end
        end

      type_from_byte =
        for {alarm_type_byte, alarm_type_name, _, _} <-
              Enum.uniq_by(@table, fn {byte, _, _, _} -> byte end) do
          quote do
            def type_from_byte(unquote(alarm_type_byte)), do: {:ok, unquote(alarm_type_name)}
          end
        end

      event_from_byte =
        for {_, type, event_byte, event} <- @table do
          quote do
            def event_from_byte(unquote(type), unquote(event_byte)), do: {:ok, unquote(event)}
          end
        end

      quote do
        @type event :: atom()

        @type type :: atom()

        @doc """
        Get the byte for the event name
        """
        @spec type_to_byte(type()) :: byte()
        unquote(type_to_byte)

        @doc """
        Get the event byte given the event type
        """
        @spec event_to_byte(type(), event()) :: byte()
        unquote(event_to_byte)

        @doc """
        Get the type from the byte
        """
        @spec type_from_byte(byte()) :: {:ok, type()} | {:error, :invalid_type_byte}
        unquote(type_from_byte)
        def type_from_byte(_), do: {:error, :invalid_type_byte}

        @doc """
        Get the event from the byte given the notification type
        """
        @spec event_from_byte(type(), byte()) :: {:ok, event()} | {:error, :invalid_event_byte}
        unquote(event_from_byte)
        def event_from_byte(_, _), do: {:error, :invalid_event_byte}
      end
    end
  end

  @type zwave_alarm_status :: :deactivate | :activate

  @before_compile Generate
end