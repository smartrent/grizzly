defmodule Grizzly.CommandClass.ManufacturerSpecific.DeviceSpecificGet do
  @moduledoc """
  Command module for working the ManufacturerSpecific command class DEVICE_SPECIFIC_GET command

  Command Options:

    * `:seq_number` - the sequence number used by the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
    * `:info` - the type of device id
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.ManufacturerSpecific

  @type t :: %__MODULE__{}

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:device_id_type, ManufacturerSpecific.device_id_type()}

  defstruct seq_number: nil, retries: 2, device_id_type: :serial_number

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number} = command) do
    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             device_id_type: {:encode_with, ManufacturerSpecific, :encode_device_id_type}
           }) do
      binary =
        Packet.header(seq_number) <>
          <<0x72, 0x06, 0x00::size(5), encoded.device_id_type::size(3)>>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, ManufacturerSpecific.device_specific_report()}
          | {:retry, t()}
          | {:queued, t()}
  def handle_response(%__MODULE__{seq_number: seq_number} = command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:continue, command}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: 0}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: n} = command, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(_command, %Packet{
        body: %{
          command_class: :manufacturer_specific,
          command: :device_specific_report,
          value: report
        }
      }) do
    {:done, {:ok, report}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response, :nack_waiting]
        } = packet
      ) do
    if Packet.sleeping_delay?(packet) do
      {:queued, command}
    else
      {:continue, command}
    end
  end

  def handle_response(command, _), do: {:continue, command}
end
