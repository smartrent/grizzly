defmodule Grizzly.ZWave.CommandClasses.UserCode do
  @moduledoc """
  Command Class for working with user codes
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x63

  @impl true
  def name(), do: :user_code
end
