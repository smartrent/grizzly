defmodule MockStatusReporter do
  @moduledoc false
  def zwave_firmware_update_status(_status), do: :ok
end
