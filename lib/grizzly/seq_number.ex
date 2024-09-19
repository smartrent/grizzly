defmodule Grizzly.SeqNumber do
  @moduledoc false

  use GenServer

  def start_link(start_number) do
    GenServer.start_link(__MODULE__, start_number, name: __MODULE__)
  end

  @spec get_and_inc() :: non_neg_integer
  def get_and_inc() do
    GenServer.call(__MODULE__, :get_and_inc)
  end

  @impl GenServer
  def init(start_number) do
    {:ok, start_number}
  end

  @impl GenServer
  def handle_call(:get_and_inc, _from, number) do
    {:reply, number, inc(number)}
  end

  defp inc(0xFF) do
    0x00
  end

  defp inc(n), do: n + 1
end
