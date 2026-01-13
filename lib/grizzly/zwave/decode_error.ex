defmodule Grizzly.ZWave.DecodeError do
  @moduledoc """
  Exception for when decoding a Z-Wave Command goes wrong
  """
  @type t :: %__MODULE__{
          value: binary() | byte() | nil,
          param: atom(),
          command: atom(),
          reason: term()
        }

  defexception [:value, :param, :command, :reason]

  def message(%{value: byte, param: param, command: command, reason: reason}) do
    msg =
      "unexpected value #{inspect(byte, base: :hex)} for param #{inspect(param, base: :hex)} when decoding binary for #{inspect(command)}"

    if reason != nil do
      msg <> ": #{inspect(reason)}"
    else
      msg
    end
  end
end
