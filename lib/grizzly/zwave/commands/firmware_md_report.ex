defmodule Grizzly.ZWave.Commands.FirmwareMDReport do
  @moduledoc """
  What does this command do??

  Params:

    * `:manufacturer_id` - A unique ID identifying the manufacturer of the device
    * `:firmware_id` - A manufacturer SHOULD assign a unique Firmware ID to each existing product variant.
    * `:checksum` - The checksum of the firmware image.
    * `:upgradable?` - Whether the Z-Wave chip is firmware upgradable
    * `:max_fragment_size` - The maximum number of Data bytes that a device is able to receive at a time
    * `:other_firmware_ids` - Ids of firmware targets other than the Z-Wave chip. Empty list if the device's only firmware target is the Z-Wave chip
    * `:hardware_version` - A value which is unique to this particular version of the product
    * `:activation_supported?` - Whether the node supports subsequent activation after Firmware Update transfer
    * `:active_during_transfer?` - Whether the supporting node’s Command Classes functionality will continue to function normally during Firmware Update transfer.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type param ::
          {:manufacturer_id, non_neg_integer}
          | {:firmware_id, non_neg_integer}
          | {:checksum, non_neg_integer}
          | {:upgradable?, boolean}
          | {:max_fragment_size, non_neg_integer}
          | {:other_firmware_ids, [non_neg_integer]}
          | {:hardware_version, byte}
          | {:activation_supported?, boolean}
          | {:active_during_transfer?, boolean}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :firmware_md_report,
      command_byte: 0x02,
      command_class: FirmwareUpdateMD,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  # version 1
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8)>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum
     ]}
  end

  # version 3
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16)>>
      ) do
    other_firmware_ids = for <<id::16 <- firmware_target_ids>>, do: id

    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_upgradable?: firmware_upgradable == 0xFF,
       max_fragment_size: max_fragment_size,
       other_firmware_ids: other_firmware_ids
     ]}
  end

  # version 5
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16), hardware_version>>
      ) do
    other_firmware_ids = for <<id::16 <- firmware_target_ids>>, do: id

    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_upgradable?: firmware_upgradable == 0xFF,
       max_fragment_size: max_fragment_size,
       other_firmware_ids: other_firmware_ids,
       hardware_version: hardware_version
     ]}
  end

  # versions 6-7
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16), hardware_version,
          _reserved::size(6), activation::size(1), cc::size(1)>>
      ) do
    other_firmware_ids = for <<id::16 <- firmware_target_ids>>, do: id

    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_upgradable?: firmware_upgradable == 0xFF,
       max_fragment_size: max_fragment_size,
       other_firmware_ids: other_firmware_ids,
       hardware_version: hardware_version,
       active_during_transfer?: cc == 0x01,
       activation_supported?: activation == 0x01
     ]}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    params = command.params |> Enum.into(%{})

    case params do
      # v6-7
      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_upgradable?: firmware_upgradable?,
        max_fragment_size: max_fragment_size,
        other_firmware_ids: other_firmware_ids,
        hardware_version: hardware_version,
        activation_supported?: activation_supported?,
        active_during_transfer?: active_during_transfer?
      } ->
        firmware_targets = Enum.count(other_firmware_ids)
        firmware_target_ids = for id <- other_firmware_ids, do: <<id::16>>, into: <<>>
        firmware_upgradable = if firmware_upgradable?, do: 0xFF, else: 0x00
        activation_supported = if activation_supported?, do: 0x01, else: 0x00
        cc = if active_during_transfer?, do: 0x01, else: 0x00

        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16), hardware_version,
          0x00::size(6), activation_supported::size(1), cc::size(1)>>

      # v5
      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_upgradable?: firmware_upgradable?,
        max_fragment_size: max_fragment_size,
        other_firmware_ids: other_firmware_ids,
        hardware_version: hardware_version
      } ->
        firmware_targets = Enum.count(other_firmware_ids)
        firmware_target_ids = for id <- other_firmware_ids, do: <<id::16>>, into: <<>>
        firmware_upgradable = if firmware_upgradable?, do: 0xFF, else: 0x00

        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16), hardware_version>>

      # v3
      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum,
        firmware_upgradable?: firmware_upgradable?,
        max_fragment_size: max_fragment_size,
        other_firmware_ids: other_firmware_ids
      } ->
        firmware_targets = Enum.count(other_firmware_ids)
        firmware_target_ids = for id <- other_firmware_ids, do: <<id::16>>, into: <<>>
        firmware_upgradable = if firmware_upgradable?, do: 0xFF, else: 0x00

        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_upgradable, firmware_targets,
          max_fragment_size::size(2)-integer-unsigned-unit(8),
          firmware_target_ids::size(firmware_targets)-binary-unit(16)>>

      # v1
      %{
        manufacturer_id: manufacturer_id,
        firmware_id: firmware_id,
        checksum: checksum
      } ->
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8)>>
    end
  end
end
