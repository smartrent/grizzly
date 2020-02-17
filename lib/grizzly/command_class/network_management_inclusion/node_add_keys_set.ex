defmodule Grizzly.CommandClass.NetworkManagementInclusion.NodeAddKeysSet do
  @moduledoc """
  Module for working with the command NODE_ADD_KEYS_SET


  opts:

  - `seq_number` - the sequence number for this command
  - `grant_csa?` - boolean to grant client side auth
  - `accept_s2?` - boolean to tell device if the controll accepts s2 bootstrapping
  - `granted_keys` - list of allowed levels for S2 security
  - `retries` - the number of times to retry sending command
  """
  @behaviour Grizzly.Command

  require Logger
  import Bitwise

  alias Grizzly.{Packet, Security}
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.NetworkManagementInclusion

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          grant_csa?: boolean(),
          accept_s2?: boolean(),
          granted_keys: [Security.key()],
          retries: non_neg_integer()
        }

  defstruct seq_number: nil, granted_keys: [], accept_s2?: true, grant_csa?: false, retries: 2

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:grant_csa?, boolean()}
          | {:accept_s2?, boolean()}
          | {:granted_keys, [Security.key()]}
          | {:retries, non_neg_integer()}

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{
          seq_number: seq_number,
          granted_keys: keys
        } = command
      ) do
    header = Packet.header(seq_number)
    keys = Security.keys_to_byte(keys)

    with {:ok, encoded} <-
           Encoding.encode_and_validate_args(command, %{
             accept_s2?:
               {:encode_with, NetworkManagementInclusion, :encode_accept_s2_bootstrapping},
             grant_csa?: {:encode_with, NetworkManagementInclusion, :encode_csa}
           }) do
      binary =
        header <> <<0x34, 0x12, seq_number, encoded.grant_csa? ||| encoded.accept_s2?, keys>>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) :: {:continue, t}
  def handle_response(%__MODULE__{seq_number: seq_number} = command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:continue, command}
  end

  # THIS IS NEVER EXECUTED
  def handle_response(command, %Packet{body: %{command: :node_add_dsk_report} = report}) do
    dsk_report_info = %{
      required_input_length: report.input_length,
      dsk: report.dsk
    }

    _ = Logger.debug(":node_add_dsk_report report = #{inspect(report)}")

    {
      :send_message,
      {:dsk_report_info, dsk_report_info},
      command
    }
  end

  def handle_response(%__MODULE__{} = command, packet) do
    _ = Logger.debug("NodeAddKeysSet is not handling response #{inspect(packet)}")
    {:continue, command}
  end

  def handle_response(command, _) do
    {:continue, command}
  end
end
