defmodule Grizzly.ZWave.Commands.ManufacturerSpecificReport do
  @moduledoc """
  Module for the MANUFACTURER_SPECIFIC_REPORT command of command class COMMAND_CLASS_MANUFACTURER_SPECIFIC
  Report the manufacturer specific information

  Params:

    * `:manufacturer_id` - unique ID for the manufacturer (required)
    * `:product_type_id` - unique ID for the product type (required)
    * `:prodcut_id` - unique ID for the actual product (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ManufacturerSpecific

  @type param ::
          {:manufacturer_id, non_neg_integer()}
          | {:product_type_id, non_neg_integer()}
          | {:product_id, non_neg_integer()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :manufacturer_specific_report,
      command_byte: 0x05,
      command_class: ManufacturerSpecific,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    manufacturer_id = Command.param!(command, :manufacturer_id)
    product_type_id = Command.param!(command, :product_type_id)
    product = Command.param!(command, :product_id)

    <<manufacturer_id::16, product_type_id::16, product::16>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<manufacturer_id::16, product_type_id::16, product_id::16>>) do
    {:ok,
     [manufacturer_id: manufacturer_id, product_type_id: product_type_id, product_id: product_id]}
  end
end
