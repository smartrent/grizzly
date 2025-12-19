defmodule Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode do
  @moduledoc """
  Command class for working with Z-Wave network updates and resetting the
  controller back to the factor defaults
  """
  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type add_mode :: :learn | :add
  @type network_update_request_status :: :done | :abort | :wait | :disabled | :overflow

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x4D

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :network_management_basic_node

  @spec add_mode_to_byte(add_mode()) :: byte()
  def add_mode_to_byte(:learn), do: 0x00
  def add_mode_to_byte(:add), do: 0x01

  @spec add_mode_from_bit(0 | 1) :: add_mode()
  def add_mode_from_bit(0), do: :learn
  def add_mode_from_bit(1), do: :add

  @spec network_update_request_status_to_byte(network_update_request_status) :: byte
  def network_update_request_status_to_byte(:done), do: 0x00
  def network_update_request_status_to_byte(:abort), do: 0x01
  def network_update_request_status_to_byte(:wait), do: 0x02
  def network_update_request_status_to_byte(:disabled), do: 0x03
  def network_update_request_status_to_byte(:overflow), do: 0x04

  @spec network_update_request_status_from_byte(byte) ::
          {:ok, network_update_request_status} | {:error, Grizzly.ZWave.DecodeError.t()}
  def network_update_request_status_from_byte(0x00), do: {:ok, :done}
  def network_update_request_status_from_byte(0x01), do: {:ok, :abort}
  def network_update_request_status_from_byte(0x02), do: {:ok, :wait}
  def network_update_request_status_from_byte(0x03), do: {:ok, :disabled}
  def network_update_request_status_from_byte(0x04), do: {:ok, :overflow}

  def network_update_request_status_from_byte(byte),
    do: {:error, %DecodeError{param: :status, value: byte}}
end
