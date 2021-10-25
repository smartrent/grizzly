defmodule Grizzly.ZWave.ZWaveError do
  @moduledoc """
  Exception for when receiving unsupported Z-Wave binary
  """
  @type t :: %__MODULE__{binary: binary()}

  defexception [:binary]

  def message(%{binary: binary}) do
    "unexpected Z-Wave binary #{inspect(binary)}"
  end
end
