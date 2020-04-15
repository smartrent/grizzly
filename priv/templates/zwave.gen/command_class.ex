defmodule <%= inspect command_class_module %> do
  @moduledoc """
  <%= inspect command_class %> Command Class

  What type of commands does this command class support?
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: # add byte here

  @impl true
  def name(), do: <%= inspect command_class_name %>
end
