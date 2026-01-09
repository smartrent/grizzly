defmodule Grizzly.ZWave.Commands.DoorLockCapabilitiesReport do
  @moduledoc """
  This command is used to advertise the Door Lock capabilities supported by the sending node.

  Params:

    * `:supported_operations` - the supported door lock operation types

    * `:supported_door_lock_modes` - the supported door lock modes

    * `:configurable_outside_handles` - which outside handles can be enabled and disabled via configuration

    * `:configurable_inside_handles` - which inside handles can be enabled and disabled via configuration

    * `:supported_door_components` - the supported door lock components that can be reported on

    * `:auto_relock_supported?` - whether the auto-relock functionality is supported

    * `:hold_and_release_supported?` - whether the hold-and-release functionality is supported

    * `:twist_assist_supported?` - whether the twist assist functionality is supported

    * `:block_to_block_supported?` - whether the block-to-block functionality is supported

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DoorLock
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:supported_operations, [DoorLock.operation_type()]}
          | {:supported_door_lock_modes, [DoorLock.mode()]}
          | {:configurable_outside_handles, [1..4]}
          | {:configurable_inside_handles, [1..4]}
          | {:supported_door_components, [DoorLock.door_components()]}
          | {:auto_relock_supported?, boolean}
          | {:hold_and_release_supported?, boolean}
          | {:twist_assist_supported?, boolean}
          | {:block_to_block_supported?, boolean}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    supported_operations_bitmask =
      Command.param!(command, :supported_operations) |> operations_to_binary()

    supported_bitmasks_length = 1
    supported_door_lock_modes = Command.param!(command, :supported_door_lock_modes)
    supported_modes_list_length = Enum.count(supported_door_lock_modes)

    supported_door_lock_modes_binary = door_lock_modes_to_binary(supported_door_lock_modes)

    configurable_outside_handles_bitmask =
      Command.param!(command, :configurable_outside_handles) |> DoorLock.door_handles_to_bitmask()

    configurable_inside_handles_bitmask =
      Command.param!(command, :configurable_inside_handles) |> DoorLock.door_handles_to_bitmask()

    supported_door_components_bitmask =
      Command.param!(command, :supported_door_components) |> door_components_to_bitmask()

    auto_relock_supported_bit =
      if Command.param!(command, :auto_relock_supported?), do: 1, else: 0

    hold_and_release_supported_bit =
      if Command.param!(command, :hold_and_release_supported?), do: 1, else: 0

    twist_assist_supported_bit =
      if Command.param!(command, :twist_assist_supported?), do: 1, else: 0

    block_to_block_supported_bit =
      if Command.param!(command, :block_to_block_supported?), do: 1, else: 0

    <<0x00::3, supported_bitmasks_length::5>> <>
      supported_operations_bitmask <>
      <<supported_modes_list_length>> <>
      supported_door_lock_modes_binary <>
      <<configurable_outside_handles_bitmask::4, configurable_inside_handles_bitmask::4>> <>
      supported_door_components_bitmask <>
      <<0x00::4, auto_relock_supported_bit::1, hold_and_release_supported_bit::1,
        twist_assist_supported_bit::1, block_to_block_supported_bit::1>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        # Assuming a single supported operations bitmask
        <<0x00::3, 0x01::5, supported_operations_bitmask, supported_modes_list_length,
          supported_door_lock_modes_binary::binary-size(supported_modes_list_length),
          configurable_outside_handles_bitmask::4, configurable_inside_handles_bitmask::4,
          supported_door_components_bitmask, 0x00::4, auto_relock_supported_bit::1,
          hold_and_release_supported_bit::1, twist_assist_supported_bit::1,
          block_to_block_supported_bit::1>>
      ) do
    supported_operations = operations_from_bitmask(supported_operations_bitmask)
    supported_modes = door_lock_modes_from_binary(supported_door_lock_modes_binary)

    {:ok,
     [
       supported_operations: supported_operations,
       supported_door_lock_modes: supported_modes,
       configurable_outside_handles:
         DoorLock.door_handles_from_bitmask(configurable_outside_handles_bitmask),
       configurable_inside_handles:
         DoorLock.door_handles_from_bitmask(configurable_inside_handles_bitmask),
       supported_door_components: door_components_from_bitmask(supported_door_components_bitmask),
       auto_relock_supported?: auto_relock_supported_bit == 1,
       hold_and_release_supported?: hold_and_release_supported_bit == 1,
       block_to_block_supported?: block_to_block_supported_bit == 1,
       twist_assist_supported?: twist_assist_supported_bit == 1
     ]}
  end

  defp operations_to_binary(operations) do
    constant_bit = if :constant_operation in operations, do: 1, else: 0
    timed_bit = if :timed_operation in operations, do: 1, else: 0
    <<0x00::5, timed_bit::1, constant_bit::1, 0x00::1>>
  end

  defp operations_from_bitmask(bitmask) do
    <<0x00::5, timed_bit::1, constant_bit::1, _reserved::1>> = <<bitmask>>

    operations = []
    operations = if timed_bit == 1, do: [:timed_operation | operations], else: operations
    if constant_bit == 1, do: [:constant_operation | operations], else: operations
  end

  defp door_components_to_bitmask(components) do
    latch_bit = if :latch in components, do: 1, else: 0
    bolt_bit = if :bolt in components, do: 1, else: 0
    door_bit = if :door in components, do: 1, else: 0
    <<0x00::5, latch_bit::1, bolt_bit::1, door_bit::1>>
  end

  defp door_components_from_bitmask(bitmask) do
    <<0x00::5, latch_bit::1, bolt_bit::1, door_bit::1>> = <<bitmask>>
    components = []
    components = if latch_bit == 1, do: [:latch | components], else: components
    components = if bolt_bit == 1, do: [:bolt | components], else: components
    if door_bit == 1, do: [:door | components], else: components
  end

  defp door_lock_modes_to_binary(modes) do
    for mode <- modes, into: <<>>, do: <<DoorLock.mode_to_byte(mode)>>
  end

  defp door_lock_modes_from_binary(binary) do
    mode_bytes = :erlang.binary_to_list(binary)
    Enum.map(mode_bytes, &DoorLock.mode_from_byte/1)
  end
end
