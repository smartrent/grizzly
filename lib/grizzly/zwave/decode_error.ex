defmodule Grizzly.ZWave.DecodeError do
  @moduledoc """
  Exception for when decoding a Z-Wave Command goes wrong
  """
  @type t :: %__MODULE__{value: byte(), param: atom(), command: atom()}

  defexception [:value, :param, :command]

  def message(%{value: byte, param: param, command: command}) do
    "unexpected value #{inspect(byte)} for param #{inspect(param)} when decoding binary for #{inspect(command)}"
  end
end
