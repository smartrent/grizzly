defmodule Grizzly.Command.EncodeError do
  @moduledoc """
  Exception for when encoding a Command goes wrong
  """
  defexception [:message]

  @type error_type ::
          {:invalid_argument_value, arg_name :: any(), arg_value :: any(), module()}

  @type t :: %__MODULE__{message: String.t()}

  @doc """
  Make a new `%EncodeError{}` from the error type
  """
  @spec new(error_type()) :: t()
  def new({:invalid_argument_value, argument_name, argument_value, command_module}) do
    %__MODULE__{
      message: """
        Invalid argument value #{inspect(argument_value)} for #{inspect(argument_name)}

        See https://hexdocs.pm/grizzly/#{inspect(command_module)}.html for more
        documentation
      """
    }
  end
end
