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

  @type param ::
          {:default, boolean}
          | {:size, 1 | 2 | 4}
          | {:handshake, boolean}
          | {:offset, non_neg_integer()}
          | {:values, [integer]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    default? = Command.param(command, :default, false)
    default_bit = if default?, do: 1, else: 0
    handshake? = Command.param(command, :handshake, false)
    handshake_bit = if handshake?, do: 1, else: 0
    size = Command.param!(command, :size)
    offset = Command.param!(command, :offset)
    values = Command.param!(command, :values)
    count = Enum.count(values)
    values_bin = for value <- values, into: <<>>, do: <<value::signed-integer-size(size)-unit(8)>>

    <<offset::16, count, default_bit::1, handshake_bit::1, 0x00::3, size::3>> <> values_bin
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<offset::16, _count, default_bit::1, handshake_bit::1, _reserved::3, size::3,
          values_bin::binary>>
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
