defmodule Grizzly.ZWave.CommandClasses.Security do
  @moduledoc """
  Security (S0) Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x98

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :security
end
