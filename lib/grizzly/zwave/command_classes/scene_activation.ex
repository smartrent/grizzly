defmodule Grizzly.ZWave.CommandClasses.SceneActivation do
  @moduledoc """
  "SceneActivation" Command Class

  The Scene Activation Command Class used for launching scenes in a number of actuator nodes
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x2B

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :scene_activation
end
