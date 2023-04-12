defmodule Grizzly.ZWave.CommandClasses.Security2 do
  @moduledoc """
  Security 2 (S2) Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x9F

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :security_2
end
