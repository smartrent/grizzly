defmodule Grizzly.Trace.Record do
  @moduledoc """
  Data structure for a single item in the trace log
  """

  require Logger

  alias Grizzly.{Trace, ZWave}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type t() :: %__MODULE__{
          timestamp: Time.t(),
          binary: binary(),
          src: Trace.src() | nil,
          dest: Trace.src() | nil
        }

  @type opt() :: {:src, Trace.src()} | {:dest, Trace.dest()} | {:timestamp, Time.t()}

  defstruct src: nil, dest: nil, binary: nil, timestamp: nil

  @doc """
  Make a new `Grizzly.Record.t()` from a binary string

  Options:
    * `:src` - the src as a string
    * `:dest` - the dest as a string
  """
  @spec new(binary(), [opt()]) :: t()
  def new(binary, opts \\ []) do
    timestamp = Keyword.get(opts, :timestamp, Time.utc_now())
    src = Keyword.get(opts, :src)
    dest = Keyword.get(opts, :dest)

    %__MODULE__{
      src: src,
      dest: dest,
      binary: binary,
      timestamp: timestamp
    }
  end

  @doc """
  Turn a record into the string format
  """
  @spec to_string(t(), Trace.format()) :: String.t()
  def to_string(record, format \\ :text)

  def to_string(record, :text) do
    %__MODULE__{timestamp: ts, src: src, dest: dest, binary: binary} = record

    prefix = "#{Time.to_string(ts)} #{src_dest_to_string(src)} #{src_dest_to_string(dest)}"

    case ZWave.from_binary(binary) do
      {:ok, zip_packet} ->
        "#{prefix} #{command_info_str(zip_packet, binary)}"

      {:error, _} ->
        "#{prefix} #{inspect(binary, limit: 500)}"
    end
  end

  def to_string(record, :raw) do
    %__MODULE__{timestamp: ts, src: src, dest: dest, binary: binary} = record

    time = ts |> Time.truncate(:millisecond) |> Time.to_string()

    "#{time} #{src_dest_to_string(src)} -> #{src_dest_to_string(dest)}: #{inspect(binary, limit: 500)}"
  end

  defp src_dest_to_string(nil) do
    Enum.reduce(1..18, "", fn _, str -> str <> " " end)
  end

  defp src_dest_to_string(src_or_dest), do: src_or_dest

  defp command_info_str(%Command{name: :keep_alive}, _binary) do
    "    keep_alive"
  end

  defp command_info_str(zip_packet, binary) do
    seq_number = Command.param!(zip_packet, :seq_number)
    flag = Command.param!(zip_packet, :flag)

    cond do
      flag == :nack_waiting ->
        expected_delay = ZIPPacket.extension(zip_packet, :expected_delay, nil)

        command_info_empty_response(seq_number, flag) <>
          " expected_delay=#{inspect(expected_delay)}"

      flag in [:ack_response, :nack_response, :nack_waiting] ->
        command_info_empty_response(seq_number, flag)

      Command.param(zip_packet, :command) == nil ->
        "    no_operation"

      true ->
        command_info_with_encapsulated_command(seq_number, zip_packet, binary)
    end
  end

  defp command_info_empty_response(seq_number, flag) do
    "#{seq_number_to_str(seq_number)} #{flag}"
  end

  defp command_info_with_encapsulated_command(seq_number, zip_packet, binary) do
    command = Command.param!(zip_packet, :command)
    command_binary = ZIPPacket.unwrap(binary)

    "#{seq_number_to_str(seq_number)} #{command.name} #{inspect(command_binary, limit: 500)}"
  rescue
    err ->
      Logger.error("""
      [Grizzly.Trace] Expected an encapsulated command, but no command param was found.

      Binary: #{inspect(binary, limit: 500)}

      This is probably a bug -- please report it along with the stack trace and, if
      possible, the corresponding line in the trace file.

      #{Exception.format(:error, err, __STACKTRACE__)}
      """)

      command_name =
        try do
          zip_packet.name
        rescue
          _ -> "UNKNOWN COMMAND"
        end

      "#{seq_number_to_str(seq_number)} ENCODING ERROR #{command_name} #{inspect(binary, limit: 500)}"
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
