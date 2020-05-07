defmodule Grizzly.ZWave.Commands.ConfigurationSet do
  @moduledoc """
  Set the configuration parameter

  Params:

    * `:size` - specifies the size of the configuration parameter
      (required if not resetting to default)
    * `:value` - the value of the parameter, can be set to `:default` to set
      the parameter back to the factory default value (required)
    * `:param_number` - the configuration parameter number to set (required)


  ## Size

  The size of the parameter are the values `1`, `2`, and `4` which is the
  number of bytes for the configuration parameter value. This should be
  provided by the user manual of our device.

  ## Factory reset a param

  If you want to factory reset a configuration parameter you can pass
  `:default` as the `:value` param
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param ::
          {:size, 1 | 2 | 4} | {:value, integer() | :default} | {:param_number, byte()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :configuration_set,
      command_byte: 0x04,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    if Command.param!(command, :value) == :default do
      encode_default(command)
    else
      encode_value_set(command)
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<param_number, 1::size(1), _rest::size(7), _>>) do
    {:ok, [param_number: param_number, value: :default]}
  end

  def decode_params(<<param_number, _::size(5), size::size(3), value::binary>>) do
    <<value_int::signed-integer-size(size)-unit(8)>> = value
    {:ok, [param_number: param_number, value: value_int, size: size]}
  end

  defp encode_default(command) do
    param_num = Command.param!(command, :param_number)

    # 0x81 is the default flag with the size at 1 byte
    # we provide a 0 value at the end
    # According to the spec the value byte has to be part of the command but if
    # the default flag is set this will be ignored
    <<param_num, 0x81, 0x00>>
  end

  defp encode_value_set(command) do
    param_num = Command.param!(command, :param_number)
    size = Command.param!(command, :size)
    value = Command.param!(command, :value)
    value_bin = <<value::signed-integer-size(size)-unit(8)>>

    <<param_num, size>> <> value_bin
  end
end
