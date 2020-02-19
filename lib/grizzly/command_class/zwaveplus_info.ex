defmodule Grizzly.CommandClass.ZwaveplusInfo do
  @type report :: %{
          version: byte,
          role_type: role_type,
          node_type: node_type,
          installer_icon_type: integer,
          user_icon_type: integer
        }

  @type role_type ::
          :controller_central_static
          | :controller_sub_static
          | :controller_portable
          | :controller_portable_reporting
          | :slave_portable
          | :slave_always_on
          | :slave_sleeping_reporting
          | :slave_sleeping_listening

  @type node_type ::
          :node
          | :ip_gateway
          | :reserved

  @spec decode_role_type(value :: 0x00..0x07) :: role_type
  def decode_role_type(0x00), do: :controller_central_static
  def decode_role_type(0x01), do: :controller_sub_static
  def decode_role_type(0x02), do: :controller_portable
  def decode_role_type(0x03), do: :controller_portable_reporting
  def decode_role_type(0x04), do: :slave_portable
  def decode_role_type(0x05), do: :slave_always_on
  def decode_role_type(0x06), do: :slave_sleeping_reporting
  def decode_role_type(0x07), do: :slave_sleeping_listening

  @spec decode_node_type(value :: byte) :: node_type
  def decode_node_type(0x00), do: :node
  def decode_node_type(0x02), do: :ip_gateway
  def decode_node_type(_byte), do: :reserved
end
