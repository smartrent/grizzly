defmodule Grizzly.Connections.KeepAliveTimer do
  @moduledoc false

  # Helpers for managing the keep alive logic for a connection

  @type t :: %__MODULE__{
          ref: reference(),
          last_send: pos_integer(),
          interval: pos_integer(),
          owner: pid()
        }

  defstruct ref: nil, interval: nil, last_send: nil, owner: nil

  @spec create(pid(), pos_integer()) :: t()
  def create(pid, interval \\ 25_000) do
    ref = Process.send_after(pid, :keep_alive_tick, interval)

    %__MODULE__{
      ref: ref,
      interval: interval,
      last_send: :os.system_time(:millisecond),
      owner: pid
    }
  end

  @spec cancel_timer(t()) :: :ok
  def cancel_timer(timer) do
    _ = Process.cancel_timer(timer.ref)
    :ok
  end

  @spec restart(t()) :: t()
  def restart(timer) do
    _ = cancel_timer(timer)
    create(self(), timer.interval)
  end
end
