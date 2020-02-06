defmodule Grizzly.ZWave.CommandClass do
  @moduledoc """
  Behaviour for a command class implementation
  """

  alias Grizzly.ZWave.CommandClasses

  @typedoc """
  A module that implements this behaviour
  """
  @type t :: module()

  @doc """
  Get the byte for the command class
  """
  @callback byte() :: byte()

  @doc """
  Get the name of the command class
  """
  @callback name() :: CommandClasses.command_class()
end
