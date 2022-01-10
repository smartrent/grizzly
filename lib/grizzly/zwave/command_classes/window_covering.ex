defmodule Grizzly.ZWave.CommandClasses.WindowCovering do
  @moduledoc """
  Window Covering Command Class

  Command class for window coverings which can be openned or closed
  """

  alias Grizzly.ZWave.DecodeError

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x6A

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :window_covering

  @type parameter_name ::
          :out_left
          | :out_left_positioned
          | :out_right
          | :out_right_positioned
          | :in_left
          | :in_left_positioned
          | :in_right
          | :in_right_positioned
          | :in_right_left
          | :in_right_left_positioned
          | :angle_vertical_slats
          | :angle_vertical_slats_positioned
          | :out_bottom
          | :out_bottom_positioned
          | :out_top
          | :out_top_positioned
          | :in_bottom
          | :in_bottom_positioned
          | :in_top
          | :in_top_positioned
          | :in_top_bottom
          | :in_top_bottom_positioned
          | :angle_horizontal_slats
          | :angle_horizontal_slats_positioned

  @spec decode_parameter_name(byte) :: {:ok, parameter_name()} | {:error, DecodeError.t()}
  def decode_parameter_name(0x00), do: {:ok, :out_left}
  def decode_parameter_name(0x01), do: {:ok, :out_left_positioned}
  def decode_parameter_name(0x02), do: {:ok, :out_right}
  def decode_parameter_name(0x03), do: {:ok, :out_right_positioned}
  def decode_parameter_name(0x04), do: {:ok, :in_left}
  def decode_parameter_name(0x05), do: {:ok, :in_left_positioned}
  def decode_parameter_name(0x06), do: {:ok, :in_right}
  def decode_parameter_name(0x07), do: {:ok, :in_right_positioned}
  def decode_parameter_name(0x08), do: {:ok, :in_right_left}
  def decode_parameter_name(0x09), do: {:ok, :in_right_left_positioned}
  def decode_parameter_name(0x0A), do: {:ok, :angle_vertical_slats}
  def decode_parameter_name(0x0B), do: {:ok, :angle_vertical_slats_positioned}
  def decode_parameter_name(0x0C), do: {:ok, :out_bottom}
  def decode_parameter_name(0x0D), do: {:ok, :out_bottom_positioned}
  def decode_parameter_name(0x0E), do: {:ok, :out_top}
  def decode_parameter_name(0x0F), do: {:ok, :out_top_positioned}
  def decode_parameter_name(0x10), do: {:ok, :in_bottom}
  def decode_parameter_name(0x11), do: {:ok, :in_bottom_positioned}
  def decode_parameter_name(0x12), do: {:ok, :in_top}
  def decode_parameter_name(0x13), do: {:ok, :in_top_positioned}
  def decode_parameter_name(0x14), do: {:ok, :in_top_bottom}
  def decode_parameter_name(0x15), do: {:ok, :in_top_bottom_positioned}
  def decode_parameter_name(0x16), do: {:ok, :angle_horizontal_slats}
  def decode_parameter_name(0x17), do: {:ok, :angle_horizontal_slats_positioned}
  def decode_parameter_name(byte), do: {:error, %DecodeError{param: :parameter_name, value: byte}}

  @spec encode_parameter_name(parameter_name()) :: byte()
  def encode_parameter_name(:out_left), do: 0x00
  def encode_parameter_name(:out_left_positioned), do: 0x01

  def encode_parameter_name(:out_right), do: 0x02
  def encode_parameter_name(:out_right_positioned), do: 0x03

  def encode_parameter_name(:in_left), do: 0x04
  def encode_parameter_name(:in_left_positioned), do: 0x05

  def encode_parameter_name(:in_right), do: 0x06
  def encode_parameter_name(:in_right_positioned), do: 0x07

  def encode_parameter_name(:in_right_left), do: 0x08
  def encode_parameter_name(:in_right_left_positioned), do: 0x09

  def encode_parameter_name(:angle_vertical_slats), do: 0x0A
  def encode_parameter_name(:angle_vertical_slats_positioned), do: 0x0B

  def encode_parameter_name(:out_bottom), do: 0x0C
  def encode_parameter_name(:out_bottom_positioned), do: 0x0D

  def encode_parameter_name(:out_top), do: 0x0E
  def encode_parameter_name(:out_top_positioned), do: 0x0F

  def encode_parameter_name(:in_bottom), do: 0x10
  def encode_parameter_name(:in_bottom_positioned), do: 0x11

  def encode_parameter_name(:in_top), do: 0x12
  def encode_parameter_name(:in_top_positioned), do: 0x13

  def encode_parameter_name(:in_top_bottom), do: 0x14
  def encode_parameter_name(:in_top_bottom_positioned), do: 0x15

  def encode_parameter_name(:angle_horizontal_slats), do: 0x16
  def encode_parameter_name(:angle_horizontal_slats_positioned), do: 0x17
end
