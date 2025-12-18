defmodule Grizzly.Trace.Record do
  @moduledoc """
  Data structure for a single item in the trace log
  """

  alias Grizzly.Trace
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  require Logger

  @type t() :: %__MODULE__{
          timestamp: Time.t(),
          binary: binary(),
          src: Trace.src() | nil,
          dest: Trace.dest() | nil
        }

  @type opt() :: {:src, Trace.src()} | {:dest, Trace.dest()} | {:timestamp, Time.t()}

  defstruct src: nil, dest: nil, binary: nil, timestamp: nil

  @doc """
  Make a new `Grizzly.Record.t()` from a binary
  """
  @spec new(Trace.src(), Trace.dest(), binary(), Time.t()) :: t()
  def new(src, dest, binary, timestamp \\ Time.utc_now()) do
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
    ts = Time.truncate(ts, :millisecond)

    prefix = "#{Time.to_string(ts)} #{src_to_string(src)} -> #{dest_to_string(dest)}"

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

    "#{time} #{src_to_string(src)} -> #{dest_to_string(dest)}: #{inspect(binary, limit: 500)}"
  end

  @doc """
  Returns the remote node in the trace record, i.e., the node that is not :grizzly.
  """
  def remote_node(%__MODULE__{src: :grizzly, dest: dest}), do: dest
  def remote_node(%__MODULE__{src: src, dest: :grizzly}), do: src

  defp src_to_string(:grizzly), do: src_to_string("G")
  defp src_to_string(src), do: src |> Kernel.to_string() |> String.pad_leading(3)

  defp dest_to_string(:grizzly), do: dest_to_string("G")
  defp dest_to_string(dest), do: dest |> Kernel.to_string() |> String.pad_trailing(3)

  defp command_info_str(%Command{name: :keep_alive} = cmd, _binary) do
    case Command.param!(cmd, :ack_flag) do
      :ack_request ->
        "    keep_alive (ack req)"

      _ ->
        "    keep_alive (ack resp)"
    end
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
    String.pad_trailing(Kernel.to_string(seq_number), 4, " ")
  end
end
