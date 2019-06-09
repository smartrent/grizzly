defmodule Grizzly.Node.Association do
  @moduledoc """
  This module is useful for working with Z-Wave Node
  Associations
  """
  alias Grizzly.Node

  @type t :: %__MODULE__{
          group: byte,
          nodes: [Node.node_id()]
        }

  @type group :: byte

  @enforce_keys [:group]
  defstruct group: nil, nodes: []

  @spec new(group, [Node.node_id()]) :: t
  def new(group, nodes \\ []) do
    struct(__MODULE__, group: group, nodes: nodes)
  end

  @spec to_keyword(t) :: keyword
  def to_keyword(%__MODULE__{} = association) do
    association
    |> Map.from_struct()
    |> Enum.into([])
  end
end
