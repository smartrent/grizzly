defmodule Grizzly.Trace.Record do
  @moduledoc """
  Data structure for a single item in the trace log
  """

  alias Grizzly.{Trace, ZWave}
  alias Grizzly.ZWave.Command

  @type t() :: %__MODULE__{
          timestamp: DateTime.t(),
          binary: binary(),
          src: Trace.src() | nil,
          dest: Trace.dest() | nil
        }

  @type opt() :: {:src, Trace.src()} | {:dest, Trace.dest()} | {:timestamp, DateTime.t()}

  defstruct src: nil, dest: nil, binary: nil, timestamp: nil

  @doc """
  Make a new `Grizzly.Record.t()` from a binary string

  Options:
    * `:src` - the src as a string
    * `:dest` - the dest as a string
  """
  @spec new(binary(), [opt()]) :: t()
  def new(binary, opts \\ []) do
    timestamp = Keyword.get(opts, :timestamp, DateTime.utc_now())
    src = Keyword.get(opts, :src)
    dest = Keyword.get(opts, :dest)

    %__MODULE__{
      src: src,
      dest: dest,
      binary: binary,
      timestamp: timestamp
    }
  end

  @spec to_pcap(t()) :: binary()
  def to_pcap(record) do
    %__MODULE__{timestamp: ts, src: {src_ip, _}, dest: {dest_ip, _}, binary: binary} = record
    ts_sec = DateTime.to_unix(ts)
    {ts_usec, _} = ts.microsecond

    src_ip = ip_to_binary(src_ip)
    dest_ip = ip_to_binary(dest_ip)

    payload =
      <<
        # version
        6::4,
        # traffic class
        0::8,
        # flow label
        0::20,
        # payload length
        byte_size(binary)::16,
        # next header
        59::8,
        # hop limit
        0::8
      >> <> src_ip <> dest_ip <> binary

    len = byte_size(payload)
    <<ts_sec::32, ts_usec::32, len::32, len::32>> <> payload
  end

  defp ip_to_binary(addr) do
    cond do
      :inet.is_ipv4_address(addr) -> addr |> ipv4_addr_to_binary()
      :inet.is_ipv6_address(addr) -> addr |> ipv6_addr_to_binary()
      true -> ipv6_addr_to_binary({0, 0, 0, 0, 0, 0, 0, 0})
    end
  end

  defp ipv4_addr_to_binary(addr) do
    addr
    |> :inet.ipv4_mapped_ipv6_address()
    |> ipv6_addr_to_binary()
  end

  defp ipv6_addr_to_binary({a, b, c, d, e, f, g, i}) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, i::16>>
  end
end

defimpl String.Chars, for: Grizzly.Trace.Record do
  import Kernel, except: [to_string: 1]

  alias Grizzly.Trace.Record
  alias Grizzly.{ZWave, ZWave.Command}

  @spec to_string(Record.t()) :: binary()
  def to_string(record) do
    %Record{timestamp: ts, src: src, dest: dest, binary: binary} = record
    {:ok, zip_packet} = ZWave.from_binary(binary)
    time = DateTime.to_time(ts)

    "#{Time.to_string(time)} #{addr_to_string(src)} #{addr_to_string(dest)} #{command_info_str(zip_packet)}"
  end

  defp addr_to_string(addr) when is_nil(addr) or addr == {nil, nil},
    do: String.pad_trailing("", 18)

  defp addr_to_string({ip, port}) do
    format_ip(ip)
    |> maybe_append_port(port)
  end

  defp format_ip(ip) do
    cond do
      is_nil(ip) -> ""
      :inet.is_ipv4_address(ip) -> :inet.ntoa(ip)
      :inet.is_ipv6_address(ip) -> "[#{:inet.ntoa(ip)}]"
      true -> ""
    end
  end

  defp maybe_append_port(str, port) when is_nil(port) or port == 0, do: str
  defp maybe_append_port(str, port), do: str <> ":#{port}"

  defp command_info_str(%Command{name: :keep_alive}) do
    "    keep_alive"
  end

  defp command_info_str(zip_packet) do
    seq_number = Command.param!(zip_packet, :seq_number)
    flag = Command.param!(zip_packet, :flag)

    case flag do
      f when f in [:ack_response, :nack_response, :nack_waiting] ->
        command_info_empty_response(seq_number, flag)

      _ ->
        command_info_with_encapsulated_command(seq_number, zip_packet)
    end
  end

  defp command_info_empty_response(seq_number, flag) do
    "#{seq_number_to_str(seq_number)} #{flag}"
  end

  defp command_info_with_encapsulated_command(seq_number, zip_packet) do
    command = Command.param!(zip_packet, :command)

    "#{seq_number_to_str(seq_number)} #{command.name} #{inspect(Command.encode_params(command))}"
  end

  defp seq_number_to_str(seq_number) do
    case seq_number do
      seq_number when seq_number < 10 ->
        "#{seq_number}  "

      seq_number when seq_number < 100 ->
        "#{seq_number} "

      seq_number ->
        "#{seq_number}"
    end
  end
end
