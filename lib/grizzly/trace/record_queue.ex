defmodule Grizzly.Trace.RecordQueue do
  @moduledoc false

  alias Grizzly.Trace.Record

  @type t() :: :queue.queue(Record.t())

  @doc """
  Create a new `RecordQueue.t()`
  """
  @spec new() :: t()
  def new() do
    :queue.new()
  end

  @doc """
  Add a record to the queue
  """
  @spec add_record(t(), Record.t()) :: t()
  def add_record(queue, record) do
    if :queue.len(queue) == 300 do
      {_value, new_queue} = :queue.out(queue)
      :queue.in(record, new_queue)
    else
      :queue.in(record, queue)
    end
  end

  @doc """
  Change a `RecordQueue.t()` to a list
  """
  @spec to_list(t()) :: [Record.t()]
  def to_list(queue) do
    :queue.to_list(queue)
  end
end
