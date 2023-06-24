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

  alias Grizzly.Trace.Record

  @type trace_opt :: {:name, atom()} | {:size, pos_integer()} | {:record_keepalives, boolean()}

  @type src() :: String.t()
  @type dest() :: String.t()

  @type log_opt() :: {:src, src()} | {:dest, dest()}

  @type format() :: :text | :term

  @default_size 300
  @default_format :text

  @doc """
  Start the trace server
  """
  @spec start_link([trace_opt()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Serialize a list of trace records into a binary. The format can be one of:

  * `:text` - Each record is on a new line and is
    formatted as `timestamp source destination sequence_number command_name
    command_binary`. This is the default format.

  * `:raw` - Each record is on a new line and is formatted as
    `timestamp source -> destination: binary`.

  * `:term` - The trace is serialized as a list of `Record.t()` structs in
    Erlang external term format. This is useful if you want to load the trace
    on another machine.
  """
  @spec format([Record.t()], format()) :: binary()
  def format(records, format \\ @default_format)

  def format(records, fmt) when fmt in [:text, :raw],
    do: Enum.map_join(records, "\n", &Record.to_string(&1, fmt))

  def format(records, :term), do: :erlang.term_to_binary(records)

  @doc """
  Dump trace records into a file. See `format/2` for the available formats.
  """
  @spec dump(binary(), format()) :: :ok | {:error, atom()}
  def dump(file, format \\ @default_format) do
    file_contents = format(list(), format)
    File.write(file, file_contents)
  end

  @doc """
  Write trace records to standard out. See `format/2` for the available formats.
  """
  @spec print(list(Record.t()), format()) :: :ok
  def print(records, :term), do: print(records, @default_format)

  def print(records, fmt) do
    IO.puts(format(records, fmt))
  end

  @spec print(list(Record.t()) | format()) :: :ok
  def print(records) when is_list(records), do: print(records, @default_format)
  def print(fmt) when is_atom(fmt), do: print(list(), fmt)

  @spec print() :: :ok
  def print(), do: print(list(), @default_format)

  @doc """
  Add a record to the trace buffer.
  """
  @spec log(GenServer.name(), binary(), [log_opt()]) :: :ok
  def log(name, binary, opts) do
    GenServer.cast(name, {:log, binary, opts})
  end

  @doc "See `log/3`"
  @spec log(binary(), [log_opt()]) :: :ok
  def log(binary, opts \\ []) when is_binary(binary), do: log(__MODULE__, binary, opts)

  @doc """
  Reset the trace buffer.
  """
  @spec clear(GenServer.name()) :: :ok
  def clear(name \\ __MODULE__) do
    GenServer.call(name, :clear)
  end

  @doc """
  List all records in the trace buffer.
  """
  @spec list(GenServer.name()) :: [Record.t()]
  def list(name \\ __MODULE__) do
    GenServer.call(name, :list)
  end

  @doc """
  Change the max size of the trace buffer from the default of #{@default_size}.
  """
  @spec resize(GenServer.name(), pos_integer()) :: :ok
  def resize(name \\ __MODULE__, size) do
    GenServer.call(name, {:resize, size})
  end

  @doc """
  Enable or disable logging of keepalive frames.
  """
  @spec record_keepalives(GenServer.name(), boolean()) :: :ok
  def record_keepalives(name \\ __MODULE__, enabled? \\ true) do
    GenServer.call(name, {:record_keepalives, enabled?})
  end

  @impl GenServer
  def init(opts) do
    size = Keyword.get(opts, :size, @default_size)
    record_keepalives = Keyword.get(opts, :record_keepalives, true)
    {:ok, %{buffer: CircularBuffer.new(size), record_keepalives: record_keepalives}}
  end

  @impl GenServer
  def handle_cast({:log, <<0x23, 0x03, _ack_flag>>, _opts}, %{record_keepalives: false} = state) do
    {:noreply, state}
  end

  def handle_cast({:log, binary, opts}, state) do
    record = Record.new(binary, opts)

    {:noreply, %{state | buffer: CircularBuffer.insert(state.buffer, record)}}
  end

  @impl GenServer
  def handle_call(:clear, _from, %{buffer: %CircularBuffer{max_size: size}} = state) do
    {:reply, :ok, %{state | buffer: CircularBuffer.new(size)}}
  end

  def handle_call(:list, _from, %{buffer: buffer} = state) do
    {:reply, CircularBuffer.to_list(buffer), state}
  end

  def handle_call({:record_keepalives, enabled?}, _from, state) do
    {:reply, :ok, %{state | record_keepalives: enabled?}}
  end

  def handle_call({:resize, size}, _from, %{buffer: buffer} = state) do
    new_buffer =
      buffer
      |> CircularBuffer.to_list()
      |> Enum.reduce(CircularBuffer.new(size), fn record, buffer ->
        CircularBuffer.insert(buffer, record)
      end)

    {:reply, :ok, %{state | buffer: new_buffer}}
  end
end
