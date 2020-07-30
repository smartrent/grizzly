defmodule Grizzly.ZWave.CommandClasses.Hail do
  @moduledoc """
  Hail Command Class

  This command class is used for a device to notify an application that the
  device has some type of information or change that the application can read.
  This command class is obsolete as of 2017-10-02. This is application and
  device specific.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x82

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :hail
end
