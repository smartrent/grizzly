defmodule Grizzly.ZWave.CommandClasses.Time do
  @moduledoc """
  "Time" Command Class

  The Time Command Class is used to read date and time from a supporting node in a Z-Wave
  network.
  """

  @type sign :: :plus | :minus

  def encode_sign(:plus), do: 0
  def encode_sign(:minus), do: 1

  def decode_sign(0), do: :plus
  def decode_sign(1), do: :minus
end
