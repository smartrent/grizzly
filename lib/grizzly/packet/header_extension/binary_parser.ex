defmodule Grizzly.Packet.HeaderExtension.BinaryParser do
  @moduledoc false
  @opaque t :: %__MODULE__{}

  defstruct bin: <<>>

  @spec from_binary(binary()) :: t()
  def from_binary(binary) do
    %__MODULE__{bin: binary}
  end

  @spec to_binary(t()) :: binary
  def to_binary(%__MODULE__{bin: bin}), do: bin

  @spec next_with(t(), (binary -> {any, binary})) :: {any, t()} | :none
  def next_with(%__MODULE__{bin: <<>>}, _), do: :none

  def next_with(%__MODULE__{bin: binary} = bp, parser) do
    {result, rest} = parser.(binary)

    {result, %{bp | bin: rest}}
  end

  @spec parse(t(), (binary -> {any, binary})) :: [any]
  def parse(%__MODULE__{} = bp, parser) do
    do_parse(bp, parser, [])
  end

  defp do_parse(bp, parser, results) do
    case next_with(bp, parser) do
      :none -> results
      {result, next_bp} -> do_parse(next_bp, parser, results ++ [result])
    end
  end
end
