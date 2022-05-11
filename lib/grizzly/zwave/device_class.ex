defmodule Grizzly.ZWave.DeviceClass do
  @moduledoc """
  Z-Wave device classes

  Z-Wave device classes allow grouping devices with the same functionality
  together. Moreover, the device class specification for specific device classes
  provide mandatory and recommended command class support.
  """

  alias Grizzly.ZWave.{DeviceClasses, CommandClasses}

  @type command_class_version() :: integer()

  @type command_class_spec() :: %{
          support: %{required(CommandClasses.command_class()) => command_class_version()},
          control: %{required(CommandClasses.command_class()) => command_class_version()}
        }

  @type t() :: %{
          basic_device_class: DeviceClasses.basic_device_class(),
          generic_device_class: DeviceClasses.generic_device_class(),
          specific_device_class: DeviceClasses.specific_device_class(),
          command_classes: command_class_spec(),
          manufacturer_id: non_neg_integer(),
          product_id: non_neg_integer(),
          product_type_id: non_neg_integer()
        }

  @doc """
  Get the command class version for the command class
  """
  @spec get_command_class_version(t(), CommandClasses.command_class()) :: non_neg_integer() | nil
  def get_command_class_version(device_class, command_class) do
    device_class.command_classes.control
    |> Map.merge(device_class.command_classes.support)
    |> Enum.find_value(fn
      {^command_class, version} -> version
      _ -> nil
    end)
  end

  @doc """
  A device class for a HVAC thermostat
  """
  @spec thermostat_hvac() :: t()
  def thermostat_hvac() do
    %{
      basic_device_class: :routing_slave,
      generic_device_class: :thermostat,
      specific_device_class: :thermostat_general_v2,
      command_classes: %{
        support: %{
          alarm: 3,
          association: 2,
          association_group_information: 1,
          basic: 1,
          battery: 1,
          device_reset_locally: 1,
          manufacturer_specific: 2,
          power_level: 1,
          security_2: 1,
          supervision: 1,
          thermostat_mode: 3,
          thermostat_set_point: 2,
          transport_service: 2,
          sensor_multilevel: 5,
          version: 2,
          zwave_plus_info: 2
        },
        control: %{wake_up: 1}
      },
      manufacturer_id: 0x0000,
      product_id: 0x0000,
      product_type_id: 0x0000
    }
  end
end
