defmodule Grizzly.ZWave.CommandClasses.SceneActivation do
  @moduledoc """
  "SceneActivation" Command Class

  The Scene Activation Command Class used for launching scenes in a number of actuator nodes
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x2B

  @impl true
  def name(), do: :scene_activation
end
