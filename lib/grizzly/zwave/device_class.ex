defmodule Grizzly.ZWave.DeviceClass do
  @moduledoc """
  Z-Wave device classes

  Z-Wave device classes allow grouping devices with the same functionality
  together. Moreover, the device class specification for specific device classes
  provide mandatory and recommended command class support.
  """

  alias Grizzly.ZWave.{DeviceClasses, CommandClasses}

  @type command_class_spec() :: %{
          support: [CommandClasses.command_class()],
          control: [CommandClasses.command_class()]
        }

  @type t() :: %{
          basic_device_class: DeviceClasses.basic_device_class(),
          generic_device_class: DeviceClasses.generic_device_class(),
          specific_device_class: DeviceClasses.specific_device_class(),
          command_classes: command_class_spec()
        }

  @spec thermostat_hvac() :: t()
  def thermostat_hvac() do
    %{
      basic_device_class: :routing_slave,
      generic_device_class: :thermostat,
      specific_device_class: :thermostat_general_v2,
      command_classes: %{
        support: [
          :association,
          :association_group_information,
          :basic,
          :batter,
          :device_reset_locally,
          :manufacturer_specific,
          :power_level,
          :security_2,
          :supervision,
          :thermostat_mode,
          :thermostat_set_point,
          :transport_service,
          :version,
          :wake_up,
          :zwave_plus_info
        ],
        control: [
          :wake_up
        ]
      }
    }
  end
end
