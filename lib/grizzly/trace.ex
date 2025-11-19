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

  @type src() :: Grizzly.node_id() | :grizzly
  @type dest() :: Grizzly.node_id() | :grizzly

  @type log_opt() :: {:src, src()} | {:dest, dest()}

  @type format() :: :text | :raw

  @type list_opt() :: {:node_id, Grizzly.node_id()}

  @default_size 300
  @default_format :text

  @doc "Start the trace server."
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
  """
  @spec format([Record.t()], format()) :: binary()
  def format(records, format \\ @default_format)

  def format(records, fmt) when fmt in [:text, :raw],
    do: Enum.map_join(records, "\n", &Record.to_string(&1, fmt))

  @doc "Dump trace records into a file using Erlang External Term Format."
  @spec dump(binary()) :: :ok | {:error, atom()}
  def dump(file) do
    file_contents = :erlang.term_to_binary(list(), compressed: 9)
    File.write(file, file_contents)
  end

  @doc """
  Write trace records to standard out. See `format/2` for the available formats.
  """
  @spec print(list(Record.t()) | format(), [list_opt()]) :: :ok
  def print(records_or_format, opts)
  def print(records, _opts) when is_list(records), do: records |> format() |> IO.puts()
  def print(fmt, opts) when is_atom(fmt), do: opts |> list() |> format(fmt) |> IO.puts()

  def print(fmt_or_opts)
  def print(fmt) when is_atom(fmt), do: print(fmt, [])
  def print(opts) when is_list(opts), do: print(@default_format, opts)

  @spec print() :: :ok
  def print(), do: print([])

  @doc "Add a record to the trace buffer."
  @spec log(GenServer.server(), src(), dest(), binary()) :: :ok
  def log(name \\ __MODULE__, src, dest, binary) do
    GenServer.cast(name, {:log, src, dest, binary})
  end

  @doc "Reset the trace buffer."
  @spec clear(GenServer.server()) :: :ok
  def clear(name \\ __MODULE__), do: GenServer.call(name, :clear)

  @doc "List all records in the trace buffer."
  @spec list(GenServer.server(), [list_opt()]) :: [Record.t()]
  def list(name, opts) do
    node_id_filter = Keyword.get(opts, :node_id, nil)
    records = GenServer.call(name, :list)

    if node_id_filter do
      Enum.filter(records, &(&1.src == node_id_filter || &1.dest == node_id_filter))
    else
      records
    end
  end

  @doc "See `list/2`."
  @spec list(GenServer.server() | [list_opt()]) :: [Record.t()]
  def list(opts) when is_list(opts), do: list(__MODULE__, opts)
  def list(name), do: list(name, [])

  @doc "See `list/2`."
  @spec list() :: [Record.t()]
  def list(), do: list(__MODULE__, [])

  @doc "Change the max size of the trace buffer from the default of #{@default_size}."
  @spec resize(GenServer.server(), pos_integer()) :: :ok
  def resize(name \\ __MODULE__, size), do: GenServer.call(name, {:resize, size})

  @doc "Enable or disable logging of keepalive frames."
  @spec record_keepalives(GenServer.server(), boolean()) :: :ok
  def record_keepalives(name, enabled?), do: GenServer.call(name, {:record_keepalives, enabled?})

  @doc "See `record_keepalives/2`."
  @spec record_keepalives(boolean()) :: :ok
  def record_keepalives(enabled? \\ true), do: record_keepalives(__MODULE__, enabled?)

  @impl GenServer
  def init(opts) do
    size = Keyword.get(opts, :size, @default_size)
    record_keepalives = Keyword.get(opts, :record_keepalives, true)
    {:ok, %{buffers: %{}, size: size, record_keepalives: record_keepalives}}
  end

  @impl GenServer
  def handle_cast(
        {:log, _src, _dest, <<0x23, 0x03, _ack_flag>>},
        %{record_keepalives: false} = state
      ) do
    {:noreply, state}
  end

  def handle_cast({:log, src, dest, binary}, state) do
    record = Record.new(src, dest, binary)

    remote_node = Record.remote_node(record)

    state =
      update_in(state.buffers[remote_node], fn
        nil -> state.size |> CircularBuffer.new() |> CircularBuffer.insert(record)
        buf -> CircularBuffer.insert(buf, record)
      end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:clear, _from, state) do
    {:reply, :ok, %{state | buffers: %{}}}
  end

  def handle_call(:list, _from, state) do
    records =
      for buffer <- Map.values(state.buffers),
          record <- buffer,
          do: record

    {:reply, Enum.sort_by(records, & &1.timestamp, {:asc, Time}), state}
  end

  def handle_call({:record_keepalives, enabled?}, _from, state) do
    {:reply, :ok, %{state | record_keepalives: enabled?}}
  end

  def handle_call({:resize, new_size}, _from, %{buffers: buffers} = state) do
    new_buffers =
      Map.new(buffers, fn {node_id, buffer} ->
        resized_buffer =
          Enum.reduce(buffer, CircularBuffer.new(new_size), fn record, new_buffer ->
            CircularBuffer.insert(new_buffer, record)
          end)

        {node_id, resized_buffer}
      end)

    {:reply, :ok, %{state | buffers: new_buffers, size: new_size}}
  end
end
