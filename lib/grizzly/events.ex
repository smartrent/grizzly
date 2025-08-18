defmodule Grizzly.Events do
  @moduledoc """
  Pubsub registry for Grizzly events other than Z-Wave commands from devices.

  ## Events

  ### Ready
  This event is emitted when Z/IP Gateway has started and Grizzly is ready to
  process commands.

  ### OTW Firmware Update
  This event is emitted when updating the firmware on the Z-Wave module. The
  payload indicates the status. See `t:Grizzly.ZWaveFirmware.update_status/0`.

  ### Serial API Status
  This event is emitted when the serial API appears to be unresponsive (or recovers
  from this state) based on Z/IP Gateway's log output.
  """

  @type event :: :ready | :otw_firmware_update | :serial_api_status

  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(_) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  @doc """
  Subscribe to one or more Grizzly events.
  """
  @spec subscribe(event() | [event()]) :: :ok
  def subscribe(event_or_events) do
    event_or_events
    |> List.wrap()
    |> Enum.each(&Registry.register(__MODULE__, &1, []))
  end

  @doc """
  Unsubscribe from one or more Grizzly events.
  """
  @spec unsubscribe(event() | [event()]) :: :ok
  def unsubscribe(event_or_events) do
    event_or_events
    |> List.wrap()
    |> Enum.each(&Registry.unregister(__MODULE__, &1))
  end

  @doc false
  @spec broadcast(event(), term()) :: :ok
  def broadcast(event, payload) do
    Registry.dispatch(__MODULE__, event, fn entries ->
      for {pid, _} <- entries do
        send(pid, {:grizzly, event, payload})
      end
    end)
  end
end
