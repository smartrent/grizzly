defmodule Grizzly.Packet.Decode do
  @moduledoc """
  A module for decoding a Z/IP Gateway binary packet
  """
  import Bitwise

  alias Grizzly.CommandClass.Mappings
  alias Grizzly.Packet.HeaderExtension

  require Logger

  @packet_types %{
    nack_option_error: 0x04,
    nack_queue_full: 0x08,
    nack_waiting: 0x10,
    nack_response: 0x20,
    ack_response: 0x40,
    ack_request: 0x80
  }

  @doc """
  Unmask the byte for which reponse types are in teh response type byte
  """
  @spec get_packet_types(binary) :: [atom]
  def get_packet_types(<<_command_data::binary-size(2), packet_types, _rest::binary>>) do
    @packet_types
    |> Enum.reduce([], fn {type, byte}, types ->
      if (packet_types &&& byte) == byte do
        types ++ [type]
      else
        types
      end
    end)
  end

  @doc """
  Get the main Z-Wave body part of the packet
  """
  @spec get_body(<<_::64>>) :: binary
  def get_body(binary) do
    header_extension_length = get_header_extension_length(binary)

    <<_header_data::binary-size(7), _extensions::binary-size(header_extension_length),
      body::binary>> = binary

    _ =
      Logger.debug(
        "BODY of #{inspect(binary)} is #{inspect(body)}, header extension length is #{
          header_extension_length
        }"
      )

    body
  end

  def get_header_extensions(<<_::binary-size(7)>>), do: []

  def get_header_extensions(<<_::binary-size(7), extension_length, rest::binary>>) do
    length = extension_length - 1
    <<extensions::binary-size(length), _::binary>> = rest

    HeaderExtension.from_binary(extensions)
  end

  @doc """
  Get the length of the header extension
  """
  def get_header_extension_length(<<_header_data::binary-size(7)>>), do: 0

  def get_header_extension_length(
        <<_header_data::binary-size(7), extension_length, _rest::binary>>
      ),
      do: extension_length

  @doc """
  Get the sequenece number from the packet
  """
  @spec get_sequence_number(<<_::64>>) :: byte()
  def get_sequence_number(bytestring) do
    # Pay the cost of reparsing body now even if we have
    # parsed it else where in the code. Maybe one day, if performance
    # is an issue we can optimize this a bit more.
    body = get_body(bytestring)

    if network_management_command_class?(body) do
      get_network_management_sequence_number(body)
    else
      get_zip_packet_sequence_number(bytestring)
    end
  end

  def get_zip_packet_sequence_number(<<_frame_data::binary-size(4), seq_no, _rest::binary>>),
    do: seq_no

  def get_network_management_sequence_number(
        <<_command_class_command::binary-size(2), seq_no, _rest::binary>>
      ),
      do: seq_no

  @doc """
  Check the body/z-wave command class to see if it is network management
  """
  def network_management_command_class?(<<0x52, _rest::binary>>), do: true
  def network_management_command_class?(<<0x34, _rest::binary>>), do: true
  def network_management_command_class?(_), do: false

  @spec raw(<<_::16>>) :: map()
  def raw(<<command_class>>), do: %{command_class: Mappings.from_byte(command_class)}

  def raw(<<0x58, 0x01, _, node_id, ip::binary-size(16), home_id::binary>>) do
    %{
      command_class: :zip_nd,
      command: :zip_node_advertisement,
      ip_address: ip_bin_to_tuple(ip),
      home_id: home_id,
      node_id: node_id
    }
  end

  def raw(<<0x58, 0x04, _, node_id>>) do
    %{
      command_class: :zip_nd,
      command: :inv_node_solicitation,
      node_id: node_id
    }
  end

  defp ip_bin_to_tuple(
         <<n1::size(16), n2::size(16), n3::size(16), n4::size(16), n5::size(16), n6::size(16),
           n7::size(16), n8::size(16)>>
       ) do
    {n1, n2, n3, n4, n5, n6, n7, n8}
  end
end
