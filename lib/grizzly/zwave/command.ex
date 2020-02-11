defmodule Grizzly.ZWave.Command do
  @moduledoc """
  Data struct and behaviour for working with Z-Wave commands
  """

  @type delay_seconds :: non_neg_integer()

  @type params :: Keyword.t()

  @type t() :: %__MODULE__{
          name: atom(),
          command_class_name: atom(),
          command_class_byte: byte(),
          command_byte: byte(),
          params: params(),
          handler: module() | {module(), any()},
          impl: module()
        }

  @enforce_keys [:name, :command_class_name, :command_byte, :command_class_byte, :impl, :handler]
  defstruct name: nil,
            params: [],
            command_class_name: nil,
            command_byte: nil,
            command_class_byte: nil,
            handler: nil,
            impl: nil

  @doc """
  Make a new `Command.t()` from the params provided

  Param validation should take place here.
  """
  @callback new(params :: keyword()) :: {:ok, t()} | {:error, reason :: any()}

  @doc """
  Encode the command parameters

  This callback is optional as not all commands have params
  """
  @callback encode_params(t()) :: binary()

  @doc """
  Decode the binary string of command params

  This callback is optional as not all commands have params
  """
  @callback decode_params(binary()) :: keyword()

  @optional_callbacks [encode_params: 1, decode_params: 1]

  @doc """
  Encode the `Command.t()` into it's binary representation
  """
  @spec to_binary(t()) :: binary()
  def to_binary(command) do
    params_bin = encode_params(command)
    <<command.command_class_byte, command.command_byte>> <> params_bin
  end

  @doc """
  Get the command param value out the params list
  """
  @spec param(t(), atom(), term()) :: term() | nil
  def param(command, param, default \\ nil) do
    if command do
      Keyword.get(command.params, param) || default
    else
      default
    end
  end

  @doc """
  Just like `param/3` but will raise if the the param is not in the param list
  """
  @spec param!(t(), atom()) :: term() | no_return()
  def param!(command, param) do
    try do
      Keyword.fetch!(command.params, param)
    rescue
      KeyError ->
        raise KeyError,
              """
              It looks like you tried to get the #{inspect(param)} from your command.

              Here is a list of available params for your command:

              """ <> list_of_command_params(command)
    end
  end

  defp list_of_command_params(command) do
    Enum.reduce(command.params, "", fn {param_name, _}, str_list ->
      str_list <> "  * #{inspect(param_name)}\n"
    end)
  end

  defp encode_params(command) do
    if command.params == [] do
      <<>>
    else
      command.impl.encode_params(command)
    end
  end
end
