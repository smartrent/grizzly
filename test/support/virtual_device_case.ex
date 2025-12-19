defmodule Grizzly.VirtualDeviceCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Grizzly.VirtualDevices

  using do
    quote do
      import Grizzly.VirtualDeviceCase
    end
  end

  def generate_id() do
    {:virtual, System.unique_integer([:positive])}
  end

  def with_virtual_device(virtual_device_impl, test) do
    virtual_device_id =
      VirtualDevices.add_device!(
        generate_id(),
        virtual_device_impl
      )

    test.(virtual_device_id)

    :ok = VirtualDevices.remove_device(virtual_device_id)
  end

  def with_virtual_devices(virtual_device_impls, test) when is_list(virtual_device_impls) do
    virtual_device_ids =
      Enum.map(
        virtual_device_impls,
        &VirtualDevices.add_device!(generate_id(), &1)
      )

    test.(virtual_device_ids)

    Enum.each(virtual_device_ids, fn id ->
      :ok = VirtualDevices.remove_device(id)
    end)
  end

  def with_virtual_devices(impl, test, number_of_devices \\ 5) when is_atom(impl) do
    impls = Enum.map(1..number_of_devices, fn _ -> impl end)
    with_virtual_devices(impls, test)
  end
end
