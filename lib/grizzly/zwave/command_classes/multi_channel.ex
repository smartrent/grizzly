defmodule Grizzly.ZWave.CommandClasses.MultiChannel do
  @moduledoc """
  "MultiChannel" Command Class

  The Multi Channel command class is used to address one or more End Points in a Multi Channel device.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @type end_point :: 1..127

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x60

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :multi_channel
end
