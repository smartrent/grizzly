defmodule Grizzly.Trace.Record do
  @moduledoc """
  Data structure for a single item in the trace log
  """

  alias Grizzly.{Trace, ZWave}
  alias Grizzly.ZWave.Command

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
  @spec to_string(t()) :: String.t()
  def to_string(record) do
    %__MODULE__{timestamp: ts, src: src, dest: dest, binary: binary} = record
    {:ok, zip_packet} = ZWave.from_binary(binary)

    "#{Time.to_string(ts)} #{src_dest_to_string(src)} #{src_dest_to_string(dest)} #{command_info_str(zip_packet)}"
  end

  defp src_dest_to_string(nil) do
    Enum.reduce(1..18, "", fn _, str -> str <> " " end)
  end

  defp src_dest_to_string(src_or_dest), do: src_or_dest

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
