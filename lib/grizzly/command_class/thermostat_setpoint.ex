defmodule Grizzly.CommandClass.ThermostatSetpoint do
  @moduledoc """
  Module for generating the thermostat setpoint command
  """

  import Bitwise

  @typedoc """
  Type for the different setpoint types.

  Possible to send raw byte for a different setpoint type if
  needed. Otherwise, `:cooling` and `:heating` atoms are the
  explicitly supported setpoint types.
  """
  @type setpoint_type :: :cooling | :heating | byte
  @type setpoint_value :: non_neg_integer

  @spec mask_opts(opts :: keyword) :: byte
  def mask_opts(opts) do
    opts
    |> Enum.reduce(0, fn {_, byte}, mask -> mask ||| byte end)
  end

  @spec encode_setpoint_type(setpoint_type) :: byte
  def encode_setpoint_type(:cooling), do: 0x02
  def encode_setpoint_type(:heating), do: 0x01
  def encode_setpoint_type(byte), do: byte

  @spec decode_setpoint_type(byte) :: setpoint_type
  def decode_setpoint_type(0x01), do: :heating
  def decode_setpoint_type(0x02), do: :cooling
  def decode_setpoint_type(byte), do: byte
end
