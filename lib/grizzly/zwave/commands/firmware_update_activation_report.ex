defmodule Grizzly.ZWave.Commands.FirmwareUpdateActivationReport do
  @moduledoc """
  This command is used to advertise the result of a firmware update operation initiated by the Firmware
  Update Activation Set Command.

  Params:

    * `status` - The status of activating the updated firmware

    * `:manufacturer_id` - A unique ID identifying the manufacturer of the device (required)

    * `:firmware_id` - A manufacturer SHOULD assign a unique Firmware ID to each existing product variant. (required)

    * `:checksum` - The checksum of the firmware image. (required)

    * `:firmware_target` - The firmware image to be updated - 0x00 for the ZWave chip, others are defined by the manufacturer (required)

    * `:hardware_version` - The hardware version (version 5)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @type status :: :invalid_identification | :activation_error | :success
  @type param ::
          {:manufacturer_id, non_neg_integer}
          | {:firmware_id, non_neg_integer}
          | {:checksum, non_neg_integer}
          | {:firmware_target, byte}
          | {:status, status}
          | {:hardware_version, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :firmware_update_activation_report,
      command_byte: 0x09,
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

    status_byte =
      Command.param!(command, :status)
      |> encode_status()

    hardware_version = Command.param(command, :hardware_version)

    if hardware_version == nil do
      <<manufacturer_id::size(2)-integer-unsigned-unit(8),
        firmware_id::size(2)-integer-unsigned-unit(8), checksum::size(2)-integer-unsigned-unit(8),
        firmware_target, status_byte>>
    else
      # version 5
      <<manufacturer_id::size(2)-integer-unsigned-unit(8),
        firmware_id::size(2)-integer-unsigned-unit(8), checksum::size(2)-integer-unsigned-unit(8),
        firmware_target, status_byte, hardware_version>>
    end
  end

  @impl true
  # version 5
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_target, status_byte,
          hardware_version>>
      ) do
    with {:ok, status} <-
           decode_status(status_byte) do
      {:ok,
       [
         manufacturer_id: manufacturer_id,
         firmware_id: firmware_id,
         firmware_target: firmware_target,
         checksum: checksum,
         status: status,
         hardware_version: hardware_version
       ]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end

  # version 1
  def decode_params(
        <<manufacturer_id::size(2)-integer-unsigned-unit(8),
          firmware_id::size(2)-integer-unsigned-unit(8),
          checksum::size(2)-integer-unsigned-unit(8), firmware_target, status_byte>>
      ) do
    with {:ok, status} <-
           decode_status(status_byte) do
      {:ok,
       [
         manufacturer_id: manufacturer_id,
         firmware_id: firmware_id,
         firmware_target: firmware_target,
         checksum: checksum,
         status: status
       ]}
    else
      {:error, %DecodeError{} = error} ->
        error
    end
  end

  defp encode_status(:invalid_identification), do: 0x00
  defp encode_status(:activation_error), do: 0x01
  defp encode_status(:success), do: 0xFF

  def decode_status(0x00), do: {:ok, :invalid_identification}
  def decode_status(0x01), do: {:ok, :activation_error}
  def decode_status(0x02), do: {:ok, :success}

  def decode_status(byte),
    do:
      {:error,
       %DecodeError{
         value: byte,
         param: :status,
         command: :firmware_update_activation_report
       }}
end
