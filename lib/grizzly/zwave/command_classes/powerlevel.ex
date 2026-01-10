defmodule Grizzly.ZWave.CommandClasses.Powerlevel do
  @moduledoc """
  "Powerlevel" Command Class

  The Powerlevel Command Class defines RF transmit power controlling Commands useful when
  installing or testing a network. The Commands makes it possible for supporting controllers to set/get
  the RF transmit power level of a node and test specific links between nodes with a specific RF transmit
  power level.
  """

  alias Grizzly.ZWave.DecodeError

  @type power_level ::
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

  @type status_of_operation :: :test_failed | :test_success | :test_in_progress

  def power_level_to_byte(:normal_power), do: 0x00
  def power_level_to_byte(:minus1dBm), do: 0x01
  def power_level_to_byte(:minus2dBm), do: 0x02
  def power_level_to_byte(:minus3dBm), do: 0x03
  def power_level_to_byte(:minus4dBm), do: 0x04
  def power_level_to_byte(:minus5dBm), do: 0x05
  def power_level_to_byte(:minus6dBm), do: 0x06
  def power_level_to_byte(:minus7dBm), do: 0x07
  def power_level_to_byte(:minus8dBm), do: 0x08
  def power_level_to_byte(:minus9dBm), do: 0x09

  def power_level_from_byte(0x00), do: {:ok, :normal_power}
  def power_level_from_byte(0x01), do: {:ok, :minus1dBm}
  def power_level_from_byte(0x02), do: {:ok, :minus2dBm}
  def power_level_from_byte(0x03), do: {:ok, :minus3dBm}
  def power_level_from_byte(0x04), do: {:ok, :minus4dBm}
  def power_level_from_byte(0x05), do: {:ok, :minus5dBm}
  def power_level_from_byte(0x06), do: {:ok, :minus6dBm}
  def power_level_from_byte(0x07), do: {:ok, :minus7dBm}
  def power_level_from_byte(0x08), do: {:ok, :minus8dBm}
  def power_level_from_byte(0x09), do: {:ok, :minus9dBm}
  def power_level_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :power_level}}

  def status_of_operation_to_byte(:test_failed), do: 0x00
  def status_of_operation_to_byte(:test_success), do: 0x01
  def status_of_operation_to_byte(:test_in_progress), do: 0x02

  def status_of_operation_from_byte(0x00), do: {:ok, :test_failed}
  def status_of_operation_from_byte(0x01), do: {:ok, :test_success}
  def status_of_operation_from_byte(0x02), do: {:ok, :test_in_progress}

  def status_of_operation_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :status_of_operation}}
end
