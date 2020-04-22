defmodule Grizzly.ZWave.CommandClasses.Alarm do
  @moduledoc """
  Alarm Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x71

  @impl true
  def name(), do: :alarm
end
