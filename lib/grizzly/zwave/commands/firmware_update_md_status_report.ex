defmodule Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport do
  @moduledoc """
  This command is used to advertise the firmware update status.

  Params:

    * `:status` the status of the firmware update

    * `:wait_time` - the time in seconds that is needed before the receiving node again becomes available
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type status ::
          :checksum_error
          | :unable_to_receive
          | :invalid_manufacturer_id
          | :invalid_firmware_id
          | :invalid_firmware_target
          | :invalid_file_header_information
          | :invalid_file_header_format
          | :insufficient_memory
          | :invalid_hardware_version
          | :successful_waiting_for_activation
          | :successful_not_restarting
          | :successful_restarting
  @type param :: {:status, status} | {:wait_time, non_neg_integer}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    status_byte = Command.param!(command, :status) |> encode_status()
    wait_time = Command.param!(command, :wait_time)
    <<status_byte, wait_time::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<status_byte, wait_time::16>>) do
    with {:ok, status} <- decode_status(status_byte) do
      {:ok, [status: status, wait_time: wait_time]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp encode_status(:checksum_error), do: 0x00
  defp encode_status(:unable_to_receive), do: 0x01
  defp encode_status(:invalid_manufacturer_id), do: 0x02
  defp encode_status(:invalid_firmware_id), do: 0x03
  defp encode_status(:invalid_firmware_target), do: 0x04
  defp encode_status(:invalid_file_header_information), do: 0x05
  defp encode_status(:invalid_file_header_format), do: 0x06
  defp encode_status(:insufficient_memory), do: 0x07
  defp encode_status(:invalid_hardware_version), do: 0x08
  defp encode_status(:successful_waiting_for_activation), do: 0xFD
  defp encode_status(:successful_not_restarting), do: 0xFE
  defp encode_status(:successful_restarting), do: 0xFF

  defp decode_status(0x00), do: {:ok, :checksum_error}
  defp decode_status(0x01), do: {:ok, :unable_to_receive}
  defp decode_status(0x02), do: {:ok, :invalid_manufacturer_id}
  defp decode_status(0x03), do: {:ok, :invalid_firmware_id}
  defp decode_status(0x04), do: {:ok, :invalid_firmware_target}
  defp decode_status(0x05), do: {:ok, :invalid_file_header_information}
  defp decode_status(0x06), do: {:ok, :invalid_file_header_format}
  defp decode_status(0x07), do: {:ok, :insufficient_memory}
  defp decode_status(0x08), do: {:ok, :invalid_hardware_version}
  defp decode_status(0xFD), do: {:ok, :successful_waiting_for_activation}
  defp decode_status(0xFE), do: {:ok, :successful_not_restarting}
  defp decode_status(0xFF), do: {:ok, :successful_restarting}

  defp decode_status(byte),
    do:
      {:error,
       %DecodeError{value: byte, param: :status, command: :firmware_update_md_status_report}}
end
