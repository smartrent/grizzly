defmodule Grizzly.ZWave.Commands.ConfigurationBulkSet do
  @moduledoc """
  This command is used to set the value of one or more configuration parameters.

  Params:

    * `:default` - This field is used to specify if the default value is to be restored for the specified configuration
                   parameters. Use carefully: Some devices will incorrectly reset ALL configuration values to default. (required)

    * `:size` - This field is used to specify the number of bytes (1, 2 or 4) of the parameter values (required)

    * `:handshake` - This field is used to indicate if a Configuration Bulk Report Command is to be returned when the
                     specified configuration parameters have been stored in non-volatile memory. (required)

    * `:offset` - This field is used to specify the first parameter in a range of one or more parameters. (required)

    * `:values` - These fields carry the values -of the same size)- to be assigned. (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param ::
          {:default, boolean}
          | {:size, 1 | 2 | 4}
          | {:handshake, boolean}
          | {:offset, non_neg_integer()}
          | {:values, [integer]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :configuration_bulk_set,
      command_byte: 0x07,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    default? = Command.param(command, :default, false)
    default_bit = if default?, do: 1, else: 0
    handshake? = Command.param(command, :handshake, false)
    handshake_bit = if handshake?, do: 1, else: 0
    size = Command.param!(command, :size)
    offset = Command.param!(command, :offset)
    values = Command.param!(command, :values)
    count = Enum.count(values)
    values_bin = for value <- values, into: <<>>, do: <<value::signed-integer-size(size)-unit(8)>>

    <<offset::size(16), count, default_bit::size(1), handshake_bit::size(1), 0x00::size(3),
      size::size(3)>> <> values_bin
  end

  @impl true
  def decode_params(
        <<offset::size(16), _count, default_bit::size(1), handshake_bit::size(1),
          _reserved::size(3), size::size(3), values_bin::binary>>
      ) do
    values = for <<value::signed-integer-size(size)-unit(8) <- values_bin>>, do: value

    {:ok,
     [
       offset: offset,
       default: default_bit == 1,
       handshake: handshake_bit == 1,
       size: size,
       values: values
     ]}
  end
end
