defmodule Grizzly.ZWave.Commands.FirmwareUpdateActivationSet do
  @moduledoc """
  This command is used to initiate the programming of a previously transferred firmware image.

  Params:

    * `:manufacturer_id` - A unique ID identifying the manufacturer of the device (required)

    * `:firmware_id` - A manufacturer SHOULD assign a unique Firmware ID to each existing product variant. (required)

    * `:checksum` - The checksum of the firmware image. (required)

    * `:firmware_target` - The firmware image to be updated - 0x00 for the ZWave chip, others are defined by the manufacturer (required)

    * `:hardware_version` - The hardware version (version 5)


  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type param ::
          {:manufacturer_id, non_neg_integer}
          | {:firmware_id, non_neg_integer}
          | {:checksum, non_neg_integer}
          | {:firmware_target, byte}
          | {:hardware_version, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :firmware_update_activation_set,
      command_byte: 0x08,
      command_class: FirmwareUpdateMD,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    manufacturer_id = Command.param!(command, :manufacturer_id)
    firmware_id = Command.param!(command, :firmware_id)
    checksum = Command.param!(command, :checksum)
    firmware_target = Command.param!(command, :firmware_target)
    hardware_version = Command.param(command, :hardware_version)

    if hardware_version == nil do
      <<manufacturer_id::2-unit(8), firmware_id::2-unit(8), checksum::2-unit(8), firmware_target>>
    else
      # version 5
      <<manufacturer_id::2-unit(8), firmware_id::2-unit(8), checksum::2-unit(8), firmware_target,
        hardware_version>>
    end
  end

  @impl true
  # version 5
  def decode_params(
        <<manufacturer_id::2-unit(8), firmware_id::2-unit(8), checksum::2-unit(8),
          firmware_target, hardware_version>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_target: firmware_target,
       hardware_version: hardware_version
     ]}
  end

  def decode_params(
        <<manufacturer_id::2-unit(8), firmware_id::2-unit(8), checksum::2-unit(8),
          firmware_target>>
      ) do
    {:ok,
     [
       manufacturer_id: manufacturer_id,
       firmware_id: firmware_id,
       checksum: checksum,
       firmware_target: firmware_target
     ]}
  end
end
