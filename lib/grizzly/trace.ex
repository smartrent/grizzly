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

  @type src() :: String.t()
  @type dest() :: String.t()

  @type log_opt() :: {:src, src()} | {:dest, dest()}

  @type format() :: :text | :term

  @doc """
  Start the trace server
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Serializes a list of trace records into a binary. The format can be one of:

  * `:text` - Each record is on a new line and is
    formatted as `timestamp source destination sequence_number command_name
    command_parameters`. This is the default format.

  * `:term` - The trace is serialized as a list of `Record.t()` structs in
    Erlang external term format. This is useful if you want to load the trace
    on another machine.
  """
  @spec format([Record.t()], format()) :: binary()
  def format(records, format \\ :text)
  def format(records, :text), do: records_to_contents(records)
  def format(records, :term), do: :erlang.term_to_binary(records)

  @doc """
  Dump the trace records into a file. See `format/2` for the available formats.
  """
  @spec dump(binary(), format()) :: :ok | {:error, atom()}
  def dump(file, format \\ :text) do
    file_contents = format(list(), format)
    File.write(file, file_contents)
  end

  @doc """
  Log the trace information
  """
  @spec log(binary(), [log_opt()]) :: :ok
  def log(binary, opts \\ []) do
    GenServer.cast(__MODULE__, {:log, binary, opts})
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
  def handle_call(:clear, _from, _records) do
    {:reply, :ok, RecordQueue.new()}
  end

  def handle_call(:list, _from, records) do
    {:reply, RecordQueue.to_list(records), records}
  end

  defp records_to_contents(records) do
    Enum.reduce(records, "", fn record, str ->
      str <> Record.to_string(record) <> "\n"
    end)
  end
end
