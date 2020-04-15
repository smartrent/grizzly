defmodule Grizzly.ZWave.Command do
  @moduledoc """
  Data struct and behaviour for working with Z-Wave commands
  """

  alias Grizzly.ZWave.CommandClass

  @type delay_seconds :: non_neg_integer()

  @type params :: Keyword.t()

  @type t() :: %__MODULE__{
          name: atom(),
          command_class: CommandClass.t(),
          command_byte: byte(),
          params: params(),
          impl: module()
        }

  @enforce_keys [
    :name,
    :command_class,
    :command_byte,
    :impl
  ]

  defstruct name: nil,
            command_byte: nil,
            command_class: nil,
            params: [],
            impl: nil

  @doc """
  Make a new `Command.t()` from the params provided

  Param validation should take place here.
  """
  @callback new(params :: keyword()) :: {:ok, t()} | {:error, reason :: any()}

  @doc """
  Encode the command parameters
  """
  @callback encode_params(t()) :: binary()

  @doc """
  Decode the binary string of command params
  """
  @callback decode_params(binary()) :: keyword()

  @doc """
  Encode the `Command.t()` into it's binary representation
  """
  @spec to_binary(t()) :: binary()
  def to_binary(command) do
    params_bin = encode_params(command)
    command_class_byte = command.command_class.byte()
    <<command_class_byte, command.command_byte>> <> params_bin
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

  @doc """
  Put the param value into the params list, updating pervious value if there is
  one
  """
  @spec put_param(t(), atom(), any()) :: t()
  def put_param(command, param, new_value) do
    new_params = Keyword.put(command.params, param, new_value)
    %__MODULE__{command | params: new_params}
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
