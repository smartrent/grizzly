defmodule Grizzly.CommandClass.Mailbox do
  @type mode :: :disabled | :mailbox_proxy_enabled | :mailbox_service_enabled

  @spec mode_from_byte(0 | 1 | 2) :: mode()
  def mode_from_byte(0x00), do: :disabled
  def mode_from_byte(0x01), do: :mailbox_service_enabled
  def mode_from_byte(0x02), do: :mailbox_proxy_enabled
end
