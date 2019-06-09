defmodule Grizzly.Packet.HeaderExtension.InstallationAndMaintenanceGet do
  defstruct critical: false

  def new() do
    struct(__MODULE__)
  end
end
