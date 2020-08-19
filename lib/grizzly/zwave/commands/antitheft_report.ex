defmodule Grizzly.ZWave.Commands.AntitheftReport do
  @moduledoc """
  This command is used to advertise the lock/unlock state of a supporting node.

  Params:

    * `:status` - the antitheft status of the device, one of :protection_disabled_unlocked , :protection_enabled_locked_fully_functional,
                  :protection_enabled_locked_restricted (required)

    * `:manufacturer_id` - This field describes the Z-Wave Manufacturer ID of the company’s product that has locked the node (required)

    * `:antitheft_hint` - This field is used as a 1 to 10 byte identifier or key value to help retriving the Magic Code (required)

    * `:locking_entity_id` - This field MUST specify a unique Z-Wave Alliance identifier for the entity that has locked the node (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Antitheft

  @type param ::
          {:status, Antitheft.status()}
          | {:manufacturer_id, non_neg_integer}
          | {:antitheft_hint, String.t()}
          | {:locking_entity_id, non_neg_integer}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :antitheft_report,
      command_byte: 0x03,
      command_class: Antitheft,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    status_byte = Command.param!(command, :status) |> Antitheft.status_to_byte()
    manufacturer_id = Command.param!(command, :manufacturer_id)

    antitheft_hint =
      Command.param!(command, :antitheft_hint) |> Antitheft.validate_magic_code_or_hint()

    locking_entity_id = Command.param!(command, :locking_entity_id)

    <<status_byte, manufacturer_id::size(16), byte_size(antitheft_hint)>> <>
      antitheft_hint <>
      <<locking_entity_id::size(16)>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<status_byte, manufacturer_id::size(16), antitheft_hint_length,
          antitheft_hint::binary-size(antitheft_hint_length), locking_entity_id::size(16)>>
      ) do
    with {:ok, status} <- Antitheft.status_from_byte(status_byte) do
      {:ok,
       [
         status: status,
         manufacturer_id: manufacturer_id,
         antitheft_hint: antitheft_hint,
         locking_entity_id: locking_entity_id
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :antitheft_report}}
    end
  end
end
