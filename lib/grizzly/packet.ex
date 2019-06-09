defmodule Grizzly.Packet do
  @moduledoc """
  Module for working with raw Z/IP packets

  This is used to marshell a Z/IP packet of bytes
  into an Elixir data structure for use to work with.

  This data structure is a more "lower level" repersentation of
  the messaging between this library and Zwave. Most the time
  you should probably be working with a `Grizzly.Message`.

  This structure is for internal btye string parsing.
  """

  # TODO: @mattludwigs - make a `to_message` function here or a `from_packet` function in
  # Grizzly.Message to have no need to expose a Packet to the client.

  require Logger
  alias Grizzly.Packet.{Decode, BodyParser, HeaderExtension}

  @type t :: %__MODULE__{
          seq_number: non_neg_integer | nil,
          body: any,
          types: [type],
          raw?: boolean,
          header_extensions: HeaderExtension.t()
        }

  @type type :: :ack_response | :nack_response | :nack_waiting

  defstruct seq_number: nil, body: nil, types: [], raw?: false, header_extensions: []

  @spec new(options :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Return Z/IP binary for the heart beat packet
  """
  @spec heart_beat() :: <<_::24>>
  def heart_beat() do
    <<0x23, 0x03, 0x80>>
  end

  @spec decode(binary) :: t()
  def decode(<<0x23, 0x03, 0x40>>) do
    %__MODULE__{types: [:ack_response], body: :heart_beat}
  end

  def decode(zip_packet_binary) do
    _ = Logger.debug("[GATEWAY]: received - #{inspect(zip_packet_binary)}")

    if raw?(zip_packet_binary) do
      body = Decode.raw(zip_packet_binary)

      %__MODULE__{raw?: true, body: body}
    else
      types = Decode.get_packet_types(zip_packet_binary)

      body =
        zip_packet_binary
        |> Decode.get_body()
        |> BodyParser.parse()

      seq_number = Decode.get_sequence_number(zip_packet_binary)
      header_extensions = Decode.get_header_extensions(zip_packet_binary)

      packet = %__MODULE__{
        types: types,
        body: body,
        seq_number: seq_number,
        header_extensions: header_extensions
      }

      packet
    end
  end

  @spec sleeping_delay?(t()) :: boolean()
  def sleeping_delay?(%__MODULE__{header_extensions: header_ext}) do
    # This function kinda a hack for right now, idealy we can add some meta
    # data to packet about which node we are communicating with, so
    # then make smarter handling of wake up nodes.
    case HeaderExtension.get_expected_delay(header_ext) do
      {:ok, seconds} when seconds > 1 -> true
      {:ok, _} -> false
      nil -> false
    end
  end

  @spec put_expected_delay(t(), seconds :: non_neg_integer()) :: t()
  def put_expected_delay(%__MODULE__{header_extensions: hext} = packet, seconds) do
    # TODO: right now we don't do any checking on which header extensions
    # are currently part of the header extensions.
    expected_delay = HeaderExtension.expected_delay_from_seconds(seconds)
    %{packet | header_extensions: [hext] ++ [expected_delay]}
  end

  @spec log(t) :: t | no_return
  def log(packet) do
    _ =
      unless heart_beat_response(packet) do
        _ = Logger.debug("Received Packet: #{inspect(packet)}")
      end

    packet
  end

  @spec header(seq_number :: non_neg_integer) :: binary
  def header(seq_number) do
    <<0x23, 0x02, 0x80, 0xD0, seq_number, 0x00, 0x00, 0x03, 0x02, 0x00>>
  end

  @spec raw?(binary() | Grizzly.Packet.t()) :: any()
  def raw?(<<0x23, _rest::binary>>), do: false
  def raw?(%__MODULE__{raw?: raw}), do: raw
  def raw?(bin) when is_binary(bin), do: true

  @spec heart_beat_response(t()) :: boolean()
  def heart_beat_response(%__MODULE__{body: :heart_beat, types: [:ack_response]}) do
    true
  end

  def heart_beat_response(%__MODULE__{}), do: false

  @spec ack_request?(t()) :: boolean
  def ack_request?(%__MODULE__{types: [:ack_request]}), do: true
  def ack_request?(%__MODULE__{}), do: false

  @spec as_ack_response(Grizzly.seq_number()) :: binary()
  def as_ack_response(seq_number) do
    <<0x23, 0x02, 0x40, 0x10, seq_number, 0x00, 0x00>>
  end
end
