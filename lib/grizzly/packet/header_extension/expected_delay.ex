defmodule Grizzly.Packet.HeaderExtension.ExpectedDelay do
  @moduledoc """
  Expected Delay is the header extension that is found in a
  Z/IP Command to indicate how many seconds until the command will be
  received by a node and processed.

  - Non-Sleeping devices: this extension does not apply
  - Frequently Listening Nodes: 1 seconds
  - Sleeping devices: > 1
  """
  @type seconds :: non_neg_integer()

  @opaque t :: %__MODULE__{
            seconds: seconds()
          }

  @enforce_keys [:seconds]
  defstruct seconds: nil

  @spec new(seconds()) :: t()
  def new(seconds) do
    struct(__MODULE__, seconds: seconds)
  end

  @doc """
  Get the number seconds of expected delay
  """
  @spec get_seconds(t()) :: seconds()
  def get_seconds(%__MODULE__{seconds: seconds}), do: seconds
end
