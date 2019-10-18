defmodule Grizzly.CommandClass.AssociationGroupInfo.GroupInfoGet do
  @moduledoc """
  Command module for working the Association Group Info command class ASSOCIATION_GROUP_INFO_GET command

  Command Options:

    * `:seq_number` - the sequence number used by the Z/IP packet
    * `:retries` - the number of attempts to send the command (default 2)
    * `:group` - The group identifier, or nil to get info on all groups
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.AssociationGroupInfo

  @type t :: %__MODULE__{}

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:group, non_neg_integer()}

  defstruct seq_number: nil, retries: 2, group: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(%__MODULE__{seq_number: seq_number, group: raw_group} = raw_command) do
    list_mode = if raw_group == nil, do: 0x01, else: 0x00
    refresh_cache = 0x00
    group = if raw_group == nil, do: 0x00, else: raw_group
    command = %__MODULE__{raw_command | group: group}

    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(command, %{
             group: :byte
           }) do
      binary =
        Packet.header(seq_number) <>
          <<0x59, 0x03, refresh_cache::size(1), list_mode::size(1), 0x00::size(6), group>>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t()}
          | {:done, {:error, :nack_response}}
          | {:done, {:done, AssociationGroupInfo.groups_info_report()}}
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
          command_class: :association_group_info,
          command: :groups_info_report,
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
