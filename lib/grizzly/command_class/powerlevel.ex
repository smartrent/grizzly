defmodule Grizzly.CommandClass.Powerlevel do
  @type power_level_report :: %{power_level: power_level_description, timeout: non_neg_integer}
  @type test_node_report :: %{
          test_node_id: non_neg_integer,
          status_of_operation: status_of_operation_description,
          test_frame_acknowledged_count: non_neg_integer
        }
  @type power_level_value :: 0x00 | 0x01 | 0x02 | 0x03 | 0x04 | 0x05 | 0x06 | 0x07 | 0x08 | 0x09
  @type power_level_description ::
          :normal_power
          | :minus1dBm
          | :minus2dBm
          | :minus3dBm
          | :minus4dBm
          | :minus5dBm
          | :minus6dBm
          | :minus7dBm
          | :minus8dBm
          | :minus9dBm
  @type status_of_operation_description :: :test_failed | :test_success | :test_in_progress
  @type status_of_operation_value :: 0x00 | 0x01 | 0x02

  require Logger

  @spec decode_power_level(power_level_value) :: power_level_description
  def decode_power_level(0x00), do: :normal_power
  def decode_power_level(0x01), do: :minus1dBm
  def decode_power_level(0x02), do: :minus2dBm
  def decode_power_level(0x03), do: :minus3dBm
  def decode_power_level(0x04), do: :minus4dBm
  def decode_power_level(0x05), do: :minus5dBm
  def decode_power_level(0x06), do: :minus6dBm
  def decode_power_level(0x07), do: :minus7dBm
  def decode_power_level(0x08), do: :minus8dBm
  def decode_power_level(0x09), do: :minus9dBm

  @spec encode_power_level(power_level_description) :: power_level_value
  def encode_power_level(:normal_power), do: 0x00
  def encode_power_level(:minus1dBm), do: 0x01
  def encode_power_level(:minus2dBm), do: 0x02
  def encode_power_level(:minus3dBm), do: 0x03
  def encode_power_level(:minus4dBm), do: 0x04
  def encode_power_level(:minus5dBm), do: 0x05
  def encode_power_level(:minus6dBm), do: 0x06
  def encode_power_level(:minus7dBm), do: 0x07
  def encode_power_level(:minus8dBm), do: 0x08
  def encode_power_level(:minus9dBm), do: 0x09

  def encode_power_level(other) do
    _ = Logger.warn("Unknown power level #{inspect(other)}. Encoding to 0x00")
    0x00
  end

  @spec decode_status_of_operation(status_of_operation_value) :: status_of_operation_description
  def decode_status_of_operation(0x00), do: :test_failed
  def decode_status_of_operation(0x01), do: :test_success
  def decode_status_of_operation(0x02), do: :test_in_progress
end
