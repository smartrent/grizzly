defmodule Grizzly.ZWave.Command do
  @moduledoc """
  Data struct and behaviour for working with Z-Wave commands
  """

  alias Grizzly.ZWave.{CommandClass, DecodeError}

  @type delay_seconds() :: non_neg_integer()

  @type params() :: Keyword.t()

  @typedoc """
  Command struct

  * `:name` - the name of the command
  * `:command_class` - the command class module for the command
  * `:command_byte` - the byte representation of the command
  * `:params` - the parameters for the command as outlined by the Z-Wave
    specification
  * `:impl` - the module that implements the Command behaviour
  """
  @type t() :: %__MODULE__{
          name: atom(),
          command_class: CommandClass.t(),
          # Allow for the NoOperation command which has no command byte, only a command class byte
          command_byte: byte() | nil,
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
  Encode the command parameters with encoding options

  The encoding options help pass extra context to how the parameters for the
  command should be encoded.

  This is an optional callback.
  """
  @callback encode_params(t(), opts :: keyword()) :: binary()

  @doc """
  Decode the binary string of command params
  """
  @callback decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}

  @doc """
  Returns true if the report is a good match for the get command. This is useful
  for commands like Version Command Class Get, which can be sent in rapid succession
  during a device interview, which can lead to reports getting matched back to the
  wrong get.

  This is an optional callback. If not implemented, command handlers will assume true.
  """
  @callback report_matches_get?(get :: t(), report :: t()) :: boolean()

  @optional_callbacks encode_params: 2, report_matches_get?: 2

  @doc """
  Encode the `Command.t()` into it's binary representation
  """
  @spec to_binary(t()) :: binary()
  def to_binary(command) do
    command_class_byte = command.command_class.byte()

    if command.command_byte != nil do
      params_bin = encode_params(command)
      <<command_class_byte, command.command_byte>> <> params_bin
    else
      # NoOperation command, for example, has no command byte or parameters
      <<command_class_byte>>
    end
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

  @spec has_param?(t(), atom()) :: boolean()
  def has_param?(command, param) do
    Keyword.has_key?(command.params, param)
  end

  @doc """
  Just like `param/3` but will raise if the the param is not in the param list
  """
  @spec param!(t(), atom()) :: term() | no_return()
  def param!(command, param) do
    Keyword.fetch!(command.params, param)
  rescue
    KeyError ->
      raise KeyError,
            """
            It looks like you tried to get the #{inspect(param)} from your command.

            Here is a list of available params for your command:

            """ <> list_of_command_params(command)
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

  @spec encode_params(t()) :: binary()
  def encode_params(command) do
    if command.params == [] do
      <<>>
    else
      command.impl.encode_params(command)
    end
  end

  defp list_of_command_params(command) do
    Enum.reduce(command.params, "", fn {param_name, _}, str_list ->
      str_list <> "  * #{inspect(param_name)}\n"
    end)
  end
end
