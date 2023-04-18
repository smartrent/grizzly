defmodule Grizzly.ZWave.CommandClasses.ZwaveplusInfo do
  @moduledoc """
  "ZwaveplusInfo" Command Class

  The Z-Wave Plus Info Command Class is used to differentiate between Z-Wave Plus, Z-Wave for IP and
  Z-Wave devices.
  """

  @behaviour Grizzly.ZWave.CommandClass
  alias Grizzly.ZWave.DecodeError

  @type role_type ::
          :central_static_controller
          | :sub_static_controller
          | :portable_controller
          | :reporting_portable_controller
          | :portable_end_node
          | :always_on_end_node
          | :reporting_sleeping_end_node
          | :listening_sleeping_end_node
          | :network_aware_end_node

  @type node_type :: :zwaveplus_node | :zwaveplus_for_ip_gateway

  @impl true
  def byte(), do: 0x5E

  @impl true
  def name(), do: :zwaveplus_info

  def role_type_to_byte(:central_static_controller), do: 0x00
  def role_type_to_byte(:sub_static_controller), do: 0x01
  def role_type_to_byte(:portable_controller), do: 0x02
  def role_type_to_byte(:reporting_portable_controller), do: 0x03
  def role_type_to_byte(:portable_end_node), do: 0x04
  def role_type_to_byte(:always_on_end_node), do: 0x05
  def role_type_to_byte(:reporting_sleeping_end_node), do: 0x06
  def role_type_to_byte(:listening_sleeping_end_node), do: 0x07
  def role_type_to_byte(:network_aware_end_node), do: 0x08

  def role_type_from_byte(0x00), do: {:ok, :central_static_controller}
  def role_type_from_byte(0x01), do: {:ok, :sub_static_controller}
  def role_type_from_byte(0x02), do: {:ok, :portable_controller}
  def role_type_from_byte(0x03), do: {:ok, :reporting_portable_controller}
  def role_type_from_byte(0x04), do: {:ok, :portable_end_node}
  def role_type_from_byte(0x05), do: {:ok, :always_on_end_node}
  def role_type_from_byte(0x06), do: {:ok, :reporting_sleeping_end_node}
  def role_type_from_byte(0x07), do: {:ok, :listening_sleeping_end_node}
  def role_type_from_byte(0x08), do: {:ok, :network_aware_end_node}
  def role_type_from_byte(byte), do: {:error, %DecodeError{param: :role_type, value: byte}}

  def node_type_to_byte(:zwaveplus_node), do: 0x00
  def node_type_to_byte(:zwaveplus_for_ip_gateway), do: 0x02

  def node_type_from_byte(0x00), do: {:ok, :zwaveplus_node}
  def node_type_from_byte(0x02), do: {:ok, :zwaveplus_for_ip_gateway}
  def node_type_from_byte(byte), do: {:error, %DecodeError{param: :node_type, value: byte}}
end
