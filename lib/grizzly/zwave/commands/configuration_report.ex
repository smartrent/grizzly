defmodule Grizzly.ZWave.Commands.ConfigurationReport do
  @moduledoc """
  Reports on a configuration parameter

  Params:

    * `:size` - specifies the size of the configuration parameter (required)
    * `:value` - the value of the parameter (required)
    * `:param_number` - the configuration parameter number reported on (required)


  ## Size

  The size of the parameter are the values `1`, `2`, and `4` which is the
  number of bytes for the configuration parameter value. This should be
  provided by the user manual of our device.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Configuration

  @type param ::
          {:size, 1 | 2 | 4} | {:value, integer()} | {:param_number, byte()}

  @impl true
  def new(params) do
    command = %Command{
      name: :configuration_report,
      command_byte: 0x06,
      command_class: Configuration,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    param_num = Command.param!(command, :param_number)
    size = Command.param!(command, :size)
    value = Command.param!(command, :value)

    <<param_num, size, value::signed-integer-size(size)-unit(8)>>
  end

  @impl true
  def decode_params(
        <<param_number, _::size(5), size::size(3), value_int::signed-integer-size(size)-unit(8)>>
      ) do
    {:ok, [param_number: param_number, value: value_int, size: size]}
  end
end
