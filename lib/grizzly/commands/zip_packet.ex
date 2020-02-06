defmodule Grizzly.Commands.ZIPPacket do
  import Bitwise
  alias Grizzly.{ZWaveCommand, CommandDecoder}

  @type flag ::
          :ack_response
          | :ack_request
          | :nack_waiting
          | :nack_queue_full
          | :nack_option_error
          | :invalid

  @type opt ::
          {:seq_number, non_neg_integer()}
          | {:dest, non_neg_integer()}
          | {:source, non_neg_integer()}
          | {:flag, flag()}
          | {:header_extensions, list()}
          | {:secure, boolean()}

  @type t :: %__MODULE__{
          command: ZWaveCommand.t() | nil,
          flag: flag() | nil,
          seq_number: non_neg_integer(),
          source: non_neg_integer(),
          dest: non_neg_integer(),
          header_extensions: list(),
          secure: boolean()
        }

  defstruct command: nil,
            flag: nil,
            seq_number: nil,
            source: nil,
            dest: nil,
            header_extensions: [],
            secure: true

  @spec flag_to_byte(flag()) :: byte()
  def flag_to_byte(:ack_request), do: 0x80
  def flag_to_byte(:ack_response), do: 0x40
  def flag_to_byte(:nack_waiting), do: 0x30
  def flag_to_byte(:nack_queue_full), do: 0x28
  def flag_to_byte(:nack_option_error), do: 0x24
  def flag_to_byte(:invalid), do: raise(ArgumentError, "Z/IP flag is invalid, cannot encode")

  def to_meta_byte(%__MODULE__{} = zip_packet) do
    meta_map = %{
      secure: zip_packet.secure,
      command: zip_packet.command,
      header_extensions: zip_packet.header_extensions
    }

    Enum.reduce(meta_map, 0, fn
      {:command, nil}, acc -> acc
      {:command, _command}, acc -> acc &&& 0x40
      {:secure, true}, acc -> acc &&& 0x20
      {:secure, false}, acc -> acc
      {:header_extensions, []}, acc -> acc
      {:header_extensions, _extensions}, acc -> acc &&& 0x80
    end)
  end

  @spec with_zwave_command(ZWaveCommand.t(), [opt]) :: t()
  def with_zwave_command(zwave_command, opts \\ []) do
    # TODO: Add validation so we don't send invalid
    # Z/IP Packets
    seq_number = Keyword.get(opts, :seq_number)
    header_extensions = Keyword.get(opts, :header_extensions, [])
    source = Keyword.get(opts, :source, 0)
    dest = Keyword.get(opts, :dest, 0)
    secure = Keyword.get(opts, :secure, true)

    %__MODULE__{
      flag: :ack_request,
      command: zwave_command,
      seq_number: seq_number,
      header_extensions: header_extensions,
      source: source,
      dest: dest,
      secure: secure
    }
  end

  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = zip_packet) do
    meta_byte = to_meta_byte(zip_packet)
    flag_byte = flag_to_byte(zip_packet.flag)
    command_binary = ZWaveCommand.to_binary(zip_packet.command)

    <<0x23, 0x02, flag_byte, meta_byte, zip_packet.seq_number, 0, 0, 0>> <> command_binary
  end

  @spec from_binary(binary()) ::
          {:ok, t()} | {:error, :invalid_zip_packet, :flag | :missing_zwave_command}
  def from_binary(<<0x23, 0x02, flags, meta, seq_number, src, dest, rest::binary>>) do
    meta = parse_meta(meta)
    command = parse_command(rest)
    flag = get_flag(flags)

    make_zip_packet(flag, command, meta, src, dest, seq_number)
  end

  defp make_zip_packet(:invalid, _, _, _, _, _), do: {:error, :invalid_zip_packet, :flags}

  defp make_zip_packet(:ack_request = flag, command, meta, src, dest, seq_number) do
    if meta.cmd do
      {:ok,
       %__MODULE__{
         command: command,
         secure: meta.secure,
         source: src,
         dest: dest,
         flag: flag,
         seq_number: seq_number
       }}
    else
      {:error, :invalid_zip_packet, :missing_zwave_command}
    end
  end

  defp make_zip_packet(:ack_response = flag, _command, meta, src, dest, seq_number) do
    {:ok,
     %__MODULE__{
       secure: meta.secure,
       source: src,
       dest: dest,
       flag: flag,
       seq_number: seq_number
     }}
  end

  defp make_zip_packet(flag, _command, meta, src, dest, seq_number)
       when flag in [:nack_waiting, :nack_queue_full, :nack_option_error] do
    {:ok,
     %__MODULE__{
       secure: meta.secure,
       source: src,
       dest: dest,
       flag: flag,
       seq_number: seq_number
     }}
  end

  defp parse_meta(meta_byte) do
    <<header?::size(1), cmd?::size(1), more_info?::size(1), secure?::size(1), _::size(4)>> =
      <<meta_byte>>

    %{
      header: bit_to_bool(header?),
      cmd: bit_to_bool(cmd?),
      more_info: bit_to_bool(more_info?),
      secure: bit_to_bool(secure?)
    }
  end

  defp parse_command(<<header_extension_length, rest::binary>>) do
    <<_extensions::binary-size(header_extension_length), command_binary::binary>> = rest

    if command_binary == "" do
      nil
    else
      CommandDecoder.from_binary(command_binary)
    end
  end

  defp bit_to_bool(1), do: true
  defp bit_to_bool(0), do: false

  defp get_flag(flag_byte) do
    case <<flag_byte>> do
      <<1::size(1), _::size(1), 1::size(1), _::size(5)>> -> :invalid
      <<_::size(1), 1::size(1), 1::size(1), _::size(5)>> -> :invalid
      <<1::size(1), _::size(7)>> -> :ack_request
      <<_::size(1), 1::size(1), _::size(6)>> -> :ack_response
      <<_::size(2), 1::size(1), 1::size(1), _::size(4)>> -> :nack_waiting
      <<_::size(2), 1::size(1), _::size(1), 1::size(1), _::size(3)>> -> :nack_queue_full
      <<_::size(2), 1::size(1), _::size(2), 1::size(1), _::size(2)>> -> :nack_option_error
      _ -> nil
    end
  end
end
