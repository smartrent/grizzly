defmodule Grizzly.VirtualDevicesRegistry do
  @moduledoc false

  alias Grizzly.VirtualDevices
  alias Grizzly.VirtualDevices.Device
  alias Grizzly.ZWave.DeviceClass

  @type start_opts() :: [
          {:keys, :unique},
          {:name, module()},
          meta: [{:inclusion_handler, Grizzly.handler()}]
        ]

  @doc """
  Function to return the options for starting this registry
  """
  @spec start_options(Grizzly.Options.t()) :: start_opts()
  def start_options(grizzly_opts) do
    [keys: :unique, name: __MODULE__, meta: [inclusion_handler: grizzly_opts.inclusion_handler]]
  end

  @doc """
  Register the virtual device
  """
  @spec register(VirtualDevices.id(), Device.t(), DeviceClass.t(), [Device.device_opt()]) ::
          {:ok, VirtualDevices.device_entry()}
          | {:error, {:already_registered, VirtualDevices.device_entry()}}
  def register({:virtual, id} = device_id, device_impl, device_class, device_opts)
      when is_integer(id) and id > 0 do
    entry = %{
      device_impl: device_impl,
      device_class: device_class,
      id: device_id,
      device_opts: device_opts
    }

    case Registry.register(__MODULE__, device_id, entry) do
      {:ok, pid} ->
        {:ok, Map.put(entry, :pid, pid)}

      {:error, {:already_registered, _pid}} ->
        {:error, {:already_registered, get(device_id)}}
    end
  end

  @doc """
  Unregister a device from the registry
  """
  @spec unregister(VirtualDevices.id()) :: :ok
  def unregister(device_id) do
    Registry.unregister(__MODULE__, device_id)
  end

  @doc """
  Get a device entry by the virtual device id
  """
  @spec get(VirtualDevices.id()) :: VirtualDevices.device_entry() | nil
  def get(device_id) do
    case Registry.lookup(__MODULE__, device_id) do
      [] ->
        nil

      [{pid, entry}] ->
        Map.put(entry, :pid, pid)
    end
  end

  @doc """
  List all the ids of the registered virtual devices
  """
  @spec list_ids() :: [VirtualDevices.id()]
  def list_ids() do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Try to get the the handler that the registry was configured to use on start
  """
  @spec get_handler() :: Grizzly.handler() | nil
  def get_handler() do
    case Registry.meta(__MODULE__, :inclusion_handler) do
      {:ok, handler} -> handler
      :error -> nil
    end
  end
end
