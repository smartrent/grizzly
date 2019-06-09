defmodule Grizzly.SeqNumber do
  @moduledoc """
  Internal module used for managing sequence numbers.

  According to Z-Wave Network documentation we have to
  have a global seq number between the values 0x00 and 0xFF (0 - 255).

  This process is used for getting the current sequence number and incrementing
  the number correctly. After hitting 0xFF (255) the numer will start back at 0x00 (0).

  This is process is only meant to be used internal to the application.
  """
  use GenServer

  def start_link(start_number) do
    GenServer.start_link(__MODULE__, start_number, name: __MODULE__)
  end

  @spec get_and_inc() :: non_neg_integer
  def get_and_inc() do
    GenServer.call(__MODULE__, :get_and_inc)
  end

  def init(start_number) do
    {:ok, start_number}
  end

  def handle_call(:get_and_inc, _from, number) do
    {:reply, number, inc(number)}
  end

  defp inc(0xFF) do
    0x00
  end

  defp inc(n), do: n + 1
end
