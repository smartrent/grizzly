defmodule Grizzly.ZWave.Commands.ZIPPacket do
  import Bitwise
  alias Grizzly.ZWave.{Command, Decoder}
  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions

  @type flag ::
          :ack_response
          | :ack_request
          | :nack_response
          | :nack_waiting
          | :nack_queue_full
          | :nack_option_error
          | :invalid

  @type opt ::
          {:seq_number, non_neg_integer()}
          | {:dest, non_neg_integer()}
          | {:source, non_neg_integer()}
          | {:flag, flag() | nil}
          | {:header_extensions, list()}
          | {:secure, boolean()}

  @enforce_keys [:seq_number]
  @type t :: %__MODULE__{
          command: Command.t() | nil,
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

  @spec flag_to_byte(flag() | nil) :: byte()
  def flag_to_byte(nil), do: 0x00
  def flag_to_byte(:ack_request), do: 0x80
  def flag_to_byte(:ack_response), do: 0x40
  def flag_to_byte(:nack_response), do: 0x20
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
      {:command, _command}, acc -> acc ||| 0x40
      {:secure, true}, acc -> acc ||| 0x10
      {:secure, false}, acc -> acc
      {:header_extensions, []}, acc -> acc
      {:header_extensions, _extensions}, acc -> acc ||| 0x80
    end)
  end

  @spec ack_response?(t()) :: boolean()
  def ack_response?(%__MODULE__{flag: :ack_response}), do: true
  def ack_response?(%__MODULE__{}), do: false

  @spec make_ack_response(Grizzly.seq_number()) :: t()
  def make_ack_response(seq_number) do
    %__MODULE__{
      seq_number: seq_number,
      flag: :ack_response,
      source: 0,
      dest: 0
    }
  end

  @doc """
  Make a `:nack_response` `ZIPPacket.t()`
  """
  @spec make_nack_response(Grizzly.seq_number()) :: t()
  def make_nack_response(seq_number) do
    %__MODULE__{
      seq_number: seq_number,
      flag: :nack_response,
      source: 0,
      dest: 0
    }
  end

  @spec make_nack_waiting_response(Command.delay_seconds(), Grizzly.seq_number()) :: t()
  def make_nack_waiting_response(delay_in_seconds, seq_number) do
    %__MODULE__{
      seq_number: seq_number,
      flag: :nack_waiting,
      header_extensions: [{:expected_delay, delay_in_seconds}],
      source: 0,
      dest: 0
    }
  end

  @doc """
  Get the extension by extension name
  """
  @spec extension(t(), atom(), any()) :: any()
  def extension(zip_packet, extension_name, default \\ nil) do
    Enum.find_value(zip_packet.header_extensions, default, fn
      {^extension_name, extension_value} -> extension_value
      _ -> false
    end)
  end

  # @spec add_extension(t(), HeaderExtensions.extension(), any()) :: t()

  @spec with_zwave_command(Command.t(), [opt]) :: t()
  def with_zwave_command(zwave_command, opts \\ []) do
    # TODO: Add validation so we don't send invalid
    # Z/IP Packets
    seq_number = Keyword.fetch!(opts, :seq_number)
    header_extensions = Keyword.get(opts, :header_extensions, [])
    source = Keyword.get(opts, :source, 0)
    dest = Keyword.get(opts, :dest, 0)
    secure = Keyword.get(opts, :secure, true)
    flag = Keyword.get(opts, :flag, :ack_request)

    %__MODULE__{
      flag: flag,
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
    header_extensions_bin = header_extensions_to_binary(zip_packet)
    header_extensions_size = byte_size(header_extensions_bin)

    if zip_packet.command != nil do
      <<0x23, 0x02, flag_byte, meta_byte, zip_packet.seq_number, 0, 0>>
      |> add_header_extensions(header_extensions_bin, header_extensions_size)
      |> add_command(zip_packet.command)
    else
      <<0x23, 0x02, flag_byte, meta_byte, zip_packet.seq_number, 0, 0>>
      |> add_header_extensions(header_extensions_bin, header_extensions_size)
    end
  end

  # only add header extensions bytes when there are some
  defp add_header_extensions(binary, _header_ex, 0), do: binary

  defp add_header_extensions(binary, header_extensions, header_extension_length),
    # add one to the header extension length byte because that byte is the length
    # for all the header extensions plus itself
    do: binary <> <<header_extension_length + 1>> <> header_extensions

  defp add_command(binary, command), do: binary <> Command.to_binary(command)

  @spec command_name(t()) :: atom() | nil
  def command_name(zip_packet) do
    if zip_packet.command do
      zip_packet.command.name
    else
      nil
    end
  end

  @spec from_binary(binary()) ::
          {:ok, t()} | {:error, :invalid_zip_packet, :flag | :missing_zwave_command}
  def from_binary(<<0x23, 0x02, flags, meta, seq_number, src, dest, rest::binary>>) do
    meta = parse_meta(meta)
    header_extensions = parse_header_extensions(rest, meta)

    case parse_command(rest, meta) do
      {:ok, command} ->
        flag = get_flag(flags)
        make_zip_packet(flag, command, meta, src, dest, seq_number, header_extensions)

      command ->
        flag = get_flag(flags)
        make_zip_packet(flag, command, meta, src, dest, seq_number, header_extensions)
    end
  end

  defp make_zip_packet(:invalid, _, _, _, _, _, _), do: {:error, :invalid_zip_packet, :flags}

  defp make_zip_packet(
         :ack_request = flag,
         command,
         meta,
         src,
         dest,
         seq_number,
         header_extensions
       ) do
    if meta.cmd do
      {:ok,
       %__MODULE__{
         command: command,
         secure: meta.secure,
         source: src,
         dest: dest,
         flag: flag,
         seq_number: seq_number,
         header_extensions: header_extensions
       }}
    else
      {:error, :invalid_zip_packet, :missing_zwave_command}
    end
  end

  defp make_zip_packet(
         :ack_response = flag,
         _command,
         meta,
         src,
         dest,
         seq_number,
         header_extensions
       ) do
    {:ok,
     %__MODULE__{
       secure: meta.secure,
       source: src,
       dest: dest,
       flag: flag,
       seq_number: seq_number,
       header_extensions: header_extensions
     }}
  end

  defp make_zip_packet(flag, command, meta, src, dest, seq_number, header_extensions) do
    {:ok,
     %__MODULE__{
       secure: meta.secure,
       source: src,
       dest: dest,
       flag: flag,
       command: command,
       seq_number: seq_number,
       header_extensions: header_extensions
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

  defp parse_header_extensions(packet_body, meta) do
    if meta.header do
      <<header_extension_length, _rest::binary>> = packet_body
      # Subtract one because the field includes itself thus leading to
      # pulling out the command class byte along with the header extension
      header_extension_length = header_extension_length - 1
      <<_, extensions_bin::binary-size(header_extension_length), _command::binary>> = packet_body

      HeaderExtensions.from_binary(extensions_bin)
    else
      []
    end
  end

  defp parse_command(_, %{cmd: false}), do: nil

  defp parse_command(<<header_extension_length, rest::binary>>, %{cmd: true, header: true}) do
    # Subtract one because the field includes itself thus leading to
    # pulling out the command class byte along with the header extension
    header_extension_length = header_extension_length - 1
    <<_extensions::binary-size(header_extension_length), command_binary::binary>> = rest

    if command_binary == "" do
      nil
    else
      Decoder.from_binary(command_binary)
    end
  end

  defp parse_command(command_binary, %{cmd: true, header: false}) do
    if command_binary == "" do
      nil
    else
      Decoder.from_binary(command_binary)
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
      <<_::size(2), 1::size(1), _::size(5)>> -> :nack_response
      _ -> nil
    end
  end

  defp header_extensions_to_binary(zip_packet) do
    HeaderExtensions.to_binary(zip_packet.header_extensions)
  end
end
