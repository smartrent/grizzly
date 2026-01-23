defmodule Grizzly.ZWave.Commands.AntitheftReport do
  @moduledoc """
  This command is used to advertise the lock/unlock state of a supporting node.

  Params:

    * `:status` - the antitheft status of the device, one of
      :protection_disabled_unlocked, :protection_enabled_locked_fully_functional,
      :protection_enabled_locked_restricted (required v2+)
    * `:manufacturer_id` - This field describes the Z-Wave Manufacturer ID of the
      company’s product that has locked the node (required v2+)
    * `:antitheft_hint` - This field is used as a 1 to 10 byte identifier or key
      value to help retrieving the Magic Code (required v2+)
    * `:locking_entity_id` - This field MUST specify a unique Z-Wave Alliance
      identifier for the entity that has locked the node (required v3 only)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type status ::
          :protection_disabled_unlocked
          | :protection_enabled_locked_fully_functional
          | :protection_enabled_locked_restricted

  @type param ::
          {:status, status()}
          | {:manufacturer_id, non_neg_integer}
          | {:antitheft_hint, String.t()}
          | {:locking_entity_id, non_neg_integer}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    status_byte = Command.param!(command, :status) |> status_to_byte()
    manufacturer_id = Command.param!(command, :manufacturer_id)
    antitheft_hint = Command.param!(command, :antitheft_hint)
    locking_entity_id = Command.param(command, :locking_entity_id)

    if locking_entity_id == nil do
      <<status_byte, manufacturer_id::16, byte_size(antitheft_hint)>> <>
        antitheft_hint
    else
      <<status_byte, manufacturer_id::16, byte_size(antitheft_hint)>> <>
        antitheft_hint <>
        <<locking_entity_id::16>>
    end
  end

  @impl Grizzly.ZWave.Command

  # v3
  def decode_params(
        _spec,
        <<status_byte, manufacturer_id::16, antitheft_hint_length,
          antitheft_hint::binary-size(antitheft_hint_length), locking_entity_id::16>>
      ) do
    with {:ok, status} <- status_from_byte(status_byte) do
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

  # v2
  def decode_params(
        _spec,
        <<status_byte, manufacturer_id::16, antitheft_hint_length,
          antitheft_hint::binary-size(antitheft_hint_length)>>
      ) do
    with {:ok, status} <- status_from_byte(status_byte) do
      {:ok,
       [
         status: status,
         manufacturer_id: manufacturer_id,
         antitheft_hint: antitheft_hint
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :antitheft_report}}
    end
  end

  defp status_to_byte(:protection_disabled_unlocked), do: 0x01
  defp status_to_byte(:protection_enabled_locked_fully_functional), do: 0x02
  defp status_to_byte(:protection_enabled_locked_restricted), do: 0x03

  defp status_from_byte(0x01), do: {:ok, :protection_disabled_unlocked}
  defp status_from_byte(0x02), do: {:ok, :protection_enabled_locked_fully_functional}
  defp status_from_byte(0x03), do: {:ok, :protection_enabled_locked_restricted}
  defp status_from_byte(byte), do: {:error, %DecodeError{value: byte, param: :status}}
end
