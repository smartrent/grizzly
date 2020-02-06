defmodule Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode do
  @moduledoc """
  Command class for working with Z-Wave network updates and resetting the
  controller back to the factor defaults
  """
  @behaviour Grizzly.ZWave.CommandClass

  @type add_mode :: :learn | :add

  @impl true
  def byte(), do: 0x4D

  @impl true
  def name(), do: :network_management_basic_node

  @spec add_mode_to_byte(add_mode()) :: byte()
  def add_mode_to_byte(:learn), do: 0x00
  def add_mode_to_byte(:add), do: 0x01

  @spec add_mode_from_bit(0 | 1) :: add_mode()
  def add_mode_from_bit(0), do: :learn
  def add_mode_from_bit(1), do: :add
end
