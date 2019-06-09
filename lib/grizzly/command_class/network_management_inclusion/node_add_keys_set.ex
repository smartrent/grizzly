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

  def encode(%__MODULE__{
        seq_number: seq_number,
        grant_csa?: csa?,
        accept_s2?: accept?,
        granted_keys: keys
      }) do
    csa_byte = encode_csa(csa?)
    accept_byte = encode_accept_s2_bootstrapping(accept?)
    header = Packet.header(seq_number)
    keys = Security.keys_to_byte(keys)

    binary = header <> <<0x34, 0x12, seq_number, csa_byte ||| accept_byte, keys>>

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) :: {:continue, t}
  def handle_response(%__MODULE__{seq_number: seq_number} = command, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:continue, command}
  end

  def handle_response(_, %Packet{body: %{command: :node_add_dsk_report} = report}) do
    dsk_report_info = %{
      required_input_length: report.input_length,
      dsk: report.dsk
    }

    {:done, {:dsk_report_info, dsk_report_info}}
  end

  def handle_response(command, packet) do
    _ = Logger.warn("Unhandled response for setting keys: #{inspect(packet)}")

    {:continue, command}
  end

  @spec encode_csa(boolean) :: 2 | 0
  def encode_csa(true), do: 2
  def encode_csa(false), do: 0

  @spec encode_accept_s2_bootstrapping(boolean) :: 1 | 0
  def encode_accept_s2_bootstrapping(true), do: 1
  def encode_accept_s2_bootstrapping(false), do: 0
end
