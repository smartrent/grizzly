defmodule Grizzly.ZWave.CommandClasses.Basic do
  @moduledoc """
  "Basic" Command Class

  Supports getting and setting the on/off state of a device
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x20

  @impl true
  def name(), do: :basic
end
