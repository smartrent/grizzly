defmodule Grizzly.FirmwareError do
  @moduledoc """
  Z-Wave firmware exception
  """
  @type t() :: %__MODULE__{message: String.t(), stack_trace: String.t(), fatal?: boolean()}

  defexception [:message, :stack_trace, :fatal?]
end
