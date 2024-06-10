defmodule Grizzly.ZWave.Commands.ConfigurationSet do
  @moduledoc """
  Set the configuration parameter

  Params:

    * `:param_number` - the configuration parameter number to set (required)
    * `:value` - the value of the parameter, can be set to `:default` to set
                 the parameter back to the factory default value (required)
    * `:size` - specifies the size of the configuration parameter
               (required if not resetting to default)
    * `:format` - one of :signed_integer, :unsigned_integer, :enumerated or :bit_field (defaults to :signed_integer)


  ## Size

  The size of the parameter are the values `1`, `2`, and `4` which is the
  number of bytes for the configuration parameter value. This should be
  provided by the user manual of our device.

  ## Factory reset a param

  If you want to factory reset a configuration parameter you can pass
  `:default` as the `:value` param

  ## Format

  The configuration value MUST be encoded according to the Format field advertised in the Configuration
  Properties Report Command for the parameter number.

  If the parameter format is “Unsigned integer”, normal binary integer encoding MUST be used.
  If the parameter format is “Signed integer”, the binary encoding MUST use the two's complement representation.
  If the parameter format is “Enumerated”, the parameter MUST be treated as an unsigned integer. A graphical configuration tool SHOULD present this parameter as a series of radio buttons.
  If the parameter format is “Bit field” the parameter MUST be treated as a bit field where each individual
  bit can be set or reset. A graphical configuration tool SHOULD present this parameter as a series of checkboxes.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param ::
          {:size, 1 | 2 | 4}
          | {:format, :signed_integer | :unsigned_integer | :enumerated | :bit_field}
          | {:value, integer() | :default}
          | {:param_number, byte()}

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
  def decode_params(<<param_number, 1::1, _rest::7, _>>) do
    {:ok, [param_number: param_number, value: :default]}
  end

  def decode_params(<<param_number, _::5, size::3, value::binary>>) do
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
    format = Command.param(command, :format, :signed_integer)
    value = Command.param!(command, :value)
    validate!(value, size, format)
    value_bin = <<value::signed-integer-size(size)-unit(8)>>

    <<param_num, size>> <> value_bin
  end

  defp validate!(value, 1, :signed_integer) when value in -128..127, do: :ok
  defp validate!(value, 2, :signed_integer) when value in -32768..32767, do: :ok
  defp validate!(value, 4, :signed_integer) when value in -2_147_483_648..2_147_483_647, do: :ok

  defp validate!(value, 1, format)
       when format in [:unsigned_integer, :enumerated, :bit_field] and value in 0..255,
       do: :ok

  defp validate!(value, 2, format)
       when format in [:unsigned_integer, :enumerated, :bit_field] and value in 0..65535,
       do: :ok

  defp validate!(value, 4, format)
       when format in [:unsigned_integer, :enumerated, :bit_field] and value in 0..4_294_967_295,
       do: :ok

  defp validate!(value, byte, format),
    do:
      raise(ArgumentError,
        message:
          "Invalid parameter. #{value} with format #{inspect(format)} will not fit in #{byte} bytes"
      )
end
