defmodule Grizzly.ZWave.CommandClasses.Alarm do
  @moduledoc """
  Alarm Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x71

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :alarm
end
