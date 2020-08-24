defmodule Grizzly.ZWave.CommandClasses.Configuration do
  @moduledoc """
  Configuration command class

  This command class is used to configure manufacturer specific configuration
  parameters
  """

  @behaviour Grizzly.ZWave.CommandClass
  alias Grizzly.ZWave.DecodeError

  @type format :: :signed_integer | :unsigned_integer | :enumerated | :bit_field

  @impl true
  def byte(), do: 0x70

  @impl true
  def name(), do: :configuration

  def format_to_byte(:signed_integer), do: 0x00
  def format_to_byte(:unsigned_integer), do: 0x01
  def format_to_byte(:enumerated), do: 0x02
  def format_to_byte(:bit_field), do: 0x03

  def format_from_byte(0x00), do: {:ok, :signed_integer}
  def format_from_byte(0x01), do: {:ok, :unsigned_integer}
  def format_from_byte(0x02), do: {:ok, :enumerated}
  def format_from_byte(0x03), do: {:ok, :bit_field}
  def format_from_byte(byte), do: {:error, %DecodeError{param: :format, value: byte}}

  def validate_size(size) when size in [0, 1, 2, 4], do: size

  def boolean_to_bit(false), do: 0
  def boolean_to_bit(true), do: 1

  def boolean_from_bit(0), do: false
  def boolean_from_bit(1), do: true
end
