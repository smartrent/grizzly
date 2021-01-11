defmodule Grizzly.Trace.RecordQueueTest do
  use ExUnit.Case, async: true

  alias Grizzly.Trace.{Record, RecordQueue}

  test "after 300 records, start dropping the first one" do
    rq = RecordQueue.new()

    {records, rq} =
      Enum.reduce(1..301, {[], rq}, fn int, {records, recq} ->
        record = Record.new(<<int>>)
        new_rq = RecordQueue.add_record(recq, record)
        records = records ++ [record]

        {records, new_rq}
      end)

    [first_record, second_record | _rest] = records

    [first_queued_record | _] = RecordQueue.to_list(rq)

    assert first_record.binary != first_queued_record.binary
    assert second_record.binary == first_queued_record.binary
  end
end
