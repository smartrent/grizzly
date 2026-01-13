defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDRequestGet do
  @moduledoc """
  The Firmware Update Meta Data Request Get Command is used to request that a firmware update be initiated.

  Params:
    * `:manufacturer_id` - A unique ID identifying the manufacturer of the device (required)
    * `:firmware_id` - A manufacturer SHOULD assign a unique Firmware ID to each existing product variant. (required)
    * `:checksum` - The checksum of the firmware image. (required)
    * `:firmware_target` - The firmware image to be updated - 0x00 for the ZWave chip, others are defined by the manufacturer (v3)
    * `:fragment_size` - The requested number of Data bytes that is to be used for firmware fragments (v3)
    * `:activation_may_be_delayed?` - Whether the receiving node may delay the actual firmware update. (V4)
    * `:hardware_version` - A value which is unique to this particular version of the product. (v5+)

  """

  @behaviour Grizzly.ZWave.Command

  @type param ::
          {:manufacturer_id, non_neg_integer}
          | {:firmware_id, non_neg_integer}
          | {:checksum, non_neg_integer}
          | {:firmware_target, byte}
          | {:fragment_size, non_neg_integer}
          | {:hardware_version, byte}
          | {:activation_may_be_delayed?, boolean}

  @impl Grizzly.ZWave.Command
  # version 1
  def decode_params(_spec, <<manufacturer_id::16, firmware_id::16, checksum::16>>) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum
     ]}
  end

  # version 3
  def decode_params(
        _spec,
        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_target: firmware_target,
       fragment_size: fragment_size
     ]}
  end

  # version 4
  def decode_params(
        _spec,
        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16,
          _::7, activation::1>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_target: firmware_target,
       fragment_size: fragment_size,
       activation_may_be_delayed?: activation == 0x01
     ]}
  end

  # version 5,6,7
  def decode_params(
        _spec,
        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16,
          _::7, activation::1, hardware_version>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_target: firmware_target,
       fragment_size: fragment_size,
       activation_may_be_delayed?: activation == 0x01,
       hardware_version: hardware_version
     ]}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    params = command.params |> Enum.into(%{})

    case params do
      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_target: firmware_target,
        fragment_size: fragment_size,
        activation_may_be_delayed?: activation_may_be_delayed?,
        # v5,6,7
        hardware_version: hardware_version
      } ->
        activation = if activation_may_be_delayed?, do: 0x01, else: 0x00

        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16,
          0x00::7, activation::1, hardware_version>>

      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_target: firmware_target,
        fragment_size: fragment_size,
        # v4
        activation_may_be_delayed?: activation_may_be_delayed?
      } ->
        activation = if activation_may_be_delayed?, do: 0x01, else: 0x00

        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16,
          0x00::7, activation::1>>

      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_target: firmware_target,
        # v3
        fragment_size: fragment_size
      } ->
        <<manufacturer_id::16, firmware_id::16, checksum::16, firmware_target, fragment_size::16>>

      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        # v1
        checksum: checksum
      } ->
        <<manufacturer_id::16, firmware_id::16, checksum::16>>
    end
  end
end
