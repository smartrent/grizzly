defmodule Grizzly.ZWave.Commands.ConfigurationPropertiesReport do
  @moduledoc """
  This command is used to advertise the properties of a configuration parameter.

  Params:

    * `:param_number` - This field is used to specify which configuration parameter (required)

    * `read_only` - This field is used to indicate if the parameter is read-only. (optional - v4+)

    * `:altering_capabilities`: - This field is used to indicate if the advertised parameter triggers a change in the node’s capabilities. (optional - v4+)

    * `:format` - This field is used to advertise the format of the parameter, one of :signed_integer, :unsigned_integer, :enumerated, :bit_field (required)

    * `:size` - This field is used to advertise the size of the actual parameter, one of 0, 1, 2, 4
                The advertised size MUST also apply to the fields “Min Value”, “Max Value”, “Default Value” carried in
                this command. (required)

    * `:min_value` - This field advertises the minimum value that the actual parameter can assume.
                     If the parameter is “Bit field”, this field MUST be set to 0. (required if size > 0 else omitted)

    * `:max_value` - This field advertises the maximum value that the actual parameter can assume.
                     If the parameter is “Bit field”, each individual supported bit MUST be set to ‘1’, while each un-
                     supported bit of MUST be set to ‘0’. (required if size > 0 else omitted)

    * `:default_value` - This field MUST advertise the default value of the actual parameter (required if size > 0 else omitted)

    * `:next_param_number` - This field advertises the next available (possibly non-sequential) configuration parameter, else 0 (required)

    * `:advanced` - This field is used to indicate if the advertised parameter is to be presented in the “Advanced”
                    parameter section in the controller GUI. (optional - v4+)

    * `:no_bulk_support` - This field is used to advertise if the sending node supports Bulk Commands. (optional - v4+)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Configuration
  import Grizzly.ZWave.Encoding

  @type param ::
          {:param_number, non_neg_integer()}
          | {:read_only, boolean | nil}
          | {:altering_capabilities, boolean | nil}
          | {:format, Configuration.format()}
          | {:size, 0 | 1 | 2 | 4}
          | {:min_value, integer | nil}
          | {:max_value, integer | nil}
          | {:default_value, integer | nil}
          | {:next_param_number, non_neg_integer()}
          | {:advanced, boolean | nil}
          | {:no_bulk_support, boolean | nil}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :configuration_properties_report,
      command_byte: 0x0F,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    param_number = Command.param!(command, :param_number)
    next_param_number = Command.param!(command, :next_param_number)
    format = Command.param!(command, :format)
    format_byte = Configuration.format_to_byte(format)
    size = Command.param!(command, :size) |> Configuration.validate_size()

    read_only_bit = Command.param(command, :read_only, false) |> bool_to_bit()

    altering_capabilities_bit =
      Command.param(command, :altering_capabilities, false) |> bool_to_bit()

    <<param_number::16, altering_capabilities_bit::1, read_only_bit::1, format_byte::3, size::3>> <>
      maybe_value_specs(command, format, size) <>
      <<next_param_number::16>> <> maybe_v4_end_byte(command)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<param_number::16, altering_capabilities_bit::1, read_only_bit::1, format_byte::3,
          0x00::3, next_param_number::16, maybe_more::binary>>
      ) do
    with {:ok, format} <- Configuration.format_from_byte(format_byte) do
      case maybe_more do
        # < v4
        <<>> ->
          {:ok,
           [
             param_number: param_number,
             format: format,
             size: 0,
             next_param_number: next_param_number
           ]}

        <<_reserved::6, no_bulk_support_bit::1, advanced_bit::1>> ->
          {:ok,
           [
             param_number: param_number,
             read_only: bit_to_bool(read_only_bit),
             advanced: bit_to_bool(advanced_bit),
             no_bulk_support: bit_to_bool(no_bulk_support_bit),
             altering_capabilities: bit_to_bool(altering_capabilities_bit),
             format: format,
             size: 0,
             next_param_number: next_param_number
           ]}
      end
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :configuration_properties_report}}
    end
  end

  def decode_params(
        <<param_number::16, altering_capabilities_bit::1, read_only_bit::1, format_byte::3,
          size::3, min_value_bin::binary-size(size), max_value_bin::binary-size(size),
          default_value_bin::binary-size(size), next_param_number::16, maybe_more::binary>>
      ) do
    with {:ok, format} <- Configuration.format_from_byte(format_byte) do
      value_specs = [
        min_value: value_spec(size, format, min_value_bin),
        max_value: value_spec(size, format, max_value_bin),
        default_value: value_spec(size, format, default_value_bin)
      ]

      case maybe_more do
        # < v4
        <<>> ->
          {:ok,
           [
             param_number: param_number,
             format: format,
             size: size,
             next_param_number: next_param_number
           ]
           |> Keyword.merge(value_specs)}

        <<_reserved::6, no_bulk_support_bit::1, advanced_bit::1>> ->
          {:ok,
           [
             param_number: param_number,
             read_only: bit_to_bool(read_only_bit),
             advanced: bit_to_bool(advanced_bit),
             no_bulk_support: bit_to_bool(no_bulk_support_bit),
             altering_capabilities: bit_to_bool(altering_capabilities_bit),
             format: format,
             size: size,
             next_param_number: next_param_number
           ]
           |> Keyword.merge(value_specs)}
      end
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :configuration_properties_report}}
    end
  end

  defp maybe_value_specs(_command, _format, 0), do: <<>>

  defp maybe_value_specs(command, format, size) do
    min_value = Command.param!(command, :min_value)
    max_value = Command.param!(command, :max_value)
    default_value = Command.param!(command, :default_value)

    case format do
      :signed_integer ->
        <<
          min_value::signed-size(size)-unit(8),
          max_value::signed-size(size)-unit(8),
          default_value::signed
        >>

      _other ->
        <<min_value::integer-size(size)-unit(8), max_value::integer-size(size)-unit(8),
          default_value::integer-size(size)-unit(8)>>
    end
  end

  defp maybe_v4_end_byte(command) do
    v4? =
      Command.param(command, :read_only) != nil or
        Command.param(command, :altering_capabilities) != nil or
        Command.param(command, :advanced) != nil or
        Command.param(command, :no_bulk_support) != nil

    if v4? do
      no_bulk_support_bit =
        Command.param!(command, :no_bulk_support) |> bool_to_bit()

      advanced_bit = Command.param!(command, :advanced) |> bool_to_bit()
      <<0x00::6, no_bulk_support_bit::1, advanced_bit::1>>
    else
      <<>>
    end
  end

  defp value_spec(size, format, value_bin) do
    case format do
      :signed_integer ->
        <<value::signed-size(size)-unit(8)>> = value_bin
        value

      _other ->
        <<value::integer-size(size)-unit(8)>> = value_bin
        value
    end
  end
end
