defmodule Grizzly.Trace do
  @moduledoc """
  Module that tracks the commands that are sent and received by Grizzly

  The trace will hold in memory the last 300 messages. If you want to generate
  a log file of the trace records you use `Grizzly.Trace.dump/1`.

  The log format is:

  ```
  timestamp source destination sequence_number command_name command_parameters
  ```

  If you want to list the records that are currently being held in memory you
  can use `Grizzly.Trace.list/0`.

  If you want to start traces from a fresh start you can call
  `Grizzly.Trace.clear/0`.
  """

  use GenServer

  alias Grizzly.Trace.{Record, RecordQueue}

  @type src() :: {:inet.ip_address(), :inet.port_number()}
  @type dest() :: {:inet.ip_address(), :inet.port_number()}
  @type format() :: :text | :pcap

  @type log_opt() :: {:src, src()} | {:dest, dest()}

  @doc """
  Start the trace server
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Log the trace information
  """
  @spec log(binary(), [log_opt()]) :: :ok
  def log(binary, opts \\ []) do
    GenServer.cast(__MODULE__, {:log, binary, opts})
  end

  @doc """
  Dump the trace records into a file
  """
  @spec dump(Path.t(), format() | nil) :: :ok
  def dump(file, format \\ nil) do
    GenServer.call(__MODULE__, {:dump, file, format})
  end

  @doc """
  Force clear the records from the trace
  """
  @spec clear() :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  List all the records currently being traced
  """
  @spec list() :: [Record.t()]
  def list() do
    GenServer.call(__MODULE__, :list)
  end

  @impl GenServer
  def init(_args) do
    {:ok, RecordQueue.new()}
  end

  @impl GenServer
  def handle_cast({:log, binary, opts}, records) do
    record = Record.new(binary, opts)

    {:noreply, RecordQueue.add_record(records, record)}
  end

  @impl GenServer
  def handle_call({:dump, file, format}, _from, records) do
    records_list = RecordQueue.to_list(records)

    file_contents =
      case detect_format(file, format) do
        :pcap -> records_to_pcap(records_list)
        :text -> records_to_text(records_list)
      end

    case File.write(file, file_contents) do
      :ok ->
        {:reply, :ok, records}

      {:error, _reason} = error ->
        {:reply, error, records}
    end
  end

  def handle_call(:clear, _from, _records) do
    {:reply, :ok, RecordQueue.new()}
  end

  def handle_call(:list, _from, records) do
    {:reply, RecordQueue.to_list(records), records}
  end

  def records_to_pcap(records) do
    # pcap global header
    header = <<
      # magic number
      0xA1B2C3D4::32,
      # major version
      2::16,
      # minor version
      4::16,
      # UTC offset
      0::32,
      # Sigfigs (set to 0 by most tools)
      0::32,
      # max length of any one captured packet
      65535::32,
      # link-layer network type
      101::32
    >>

    records_binary =
      Enum.reduce(records, <<>>, fn record, acc ->
        acc <> Record.to_pcap(record)
      end)

    header <> records_binary
  end

  defp records_to_text(records) do
    Enum.reduce(records, "", fn record, str ->
      str <> to_string(record) <> "\n"
    end)
  end

  @spec detect_format(binary(), format()) :: format()
  defp detect_format(filename, format) do
    cond do
      not is_nil(format) -> format
      String.ends_with?(filename, ".pcap") -> :pcap
      true -> :text
    end
  end
end
