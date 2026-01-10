defmodule Grizzly.ZWave.CommandClasses.ApplicationStatus do
  @moduledoc """
  "ApplicationStatus" Command Class

  This command class is used by devices to report an exceptional status for a received command request (try later or rejected.)
  """

  alias Grizzly.ZWave.DecodeError

  @type status :: :try_again_later | :try_again_after_wait | :request_queued

  def status_to_byte(:try_again_later), do: 0x00
  def status_to_byte(:try_again_after_wait), do: 0x01
  def status_to_byte(:request_queued), do: 0x02

  def status_from_byte(0x00), do: {:ok, :try_again_later}
  def status_from_byte(0x01), do: {:ok, :try_again_after_wait}
  def status_from_byte(0x02), do: {:ok, :request_queued}
  def status_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :status}}
end
