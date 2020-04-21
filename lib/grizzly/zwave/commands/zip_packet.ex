defmodule Grizzly.ZWave.Commands.ZIPPacket do
  @moduledoc """
  Command for sending Z-Wave commands via Z/IP
  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise
  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, Decoder}
  alias Grizzly.ZWave.CommandClasses.ZIP
  alias Grizzly.ZWave.Commands.ZIPPacket.HeaderExtensions

  @type flag ::
          :ack_response
          | :ack_request
          | :nack_response
          | :nack_waiting
          | :nack_queue_full
          | :nack_option_error
          | :invalid

  @type param ::
          {:command, Command.t() | nil}
          | {:flag, flag()}
          | {:seq_number, ZWave.seq_number()}
          | {:source, ZWave.node_id()}
          | {:dest, ZWave.node_id()}
          | {:header_extensions, [HeaderExtensions.extension()]}
          | {:secure, boolean()}

  @default_params [
    source: 0x00,
    dest: 0x00,
    secure: true,
    header_extensions: [],
    flag: nil,
    command: nil
  ]

  @impl true
  def new(params \\ []) do
    # TODO: validate params
    command = %Command{
      name: :zip_packet,
      command_byte: 0x02,
      command_class: ZIP,
      params: Keyword.merge(@default_params, params),
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    zwave_command = Command.param(command, :command)
    flag = Command.param(command, :flag)
    seq_number = Command.param!(command, :seq_number)
    source = Command.param!(command, :source)
    dest = Command.param!(command, :dest)
    header_extensions = Command.param!(command, :header_extensions)
    secure = Command.param!(command, :secure)

    meta_byte = meta_to_byte(secure, zwave_command, header_extensions)

    <<flag_to_byte(flag), meta_byte, seq_number, source, dest>>
    |> maybe_add_header_extensions(header_extensions)
    |> maybe_add_command(zwave_command)
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(
        <<flag_byte, meta_byte, seq_number, source, dest, extensions_and_command::binary>>
      ) do
    meta = meta_from_byte(meta_byte)
    header_extensions = parse_header_extensions(extensions_and_command, meta)
    {:ok, command} = parse_command(extensions_and_command, meta)
    flag = flag_from_byte(flag_byte)

    {:ok,
     [
       seq_number: seq_number,
       source: source,
       dest: dest,
       secure: meta.secure,
       header_extensions: header_extensions,
       command: command,
       flag: flag
     ]}
  end

  @spec flag_to_byte(flag() | nil) :: byte()
  def flag_to_byte(nil), do: 0x00
  def flag_to_byte(:ack_request), do: 0x80
  def flag_to_byte(:ack_response), do: 0x40
  def flag_to_byte(:nack_response), do: 0x20
  def flag_to_byte(:nack_waiting), do: 0x30
  def flag_to_byte(:nack_queue_full), do: 0x28
  def flag_to_byte(:nack_option_error), do: 0x24
  def flag_to_byte(:invalid), do: raise(ArgumentError, "Z/IP flag is invalid, cannot encode")

  def meta_to_byte(secure, command, extensions) do
    meta_map = %{
      secure: secure,
      command: command,
      header_extensions: extensions
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

  @spec ack_response?(Command.t()) :: boolean()
  def ack_response?(command) do
    Command.param!(command, :flag) == :ack_response
  end

  @spec make_ack_response(ZWave.seq_number()) :: Command.t()
  def make_ack_response(seq_number) do
    {:ok, command} = new(seq_number: seq_number, flag: :ack_response)
    command
  end

  @doc """
  Make a `:nack_response`
  """
  @spec make_nack_response(ZWave.seq_number()) :: Command.t()
  def make_nack_response(seq_number) do
    {:ok, command} = new(seq_number: seq_number, flag: :nack_response)
    command
  end

  @spec make_nack_waiting_response(ZWave.seq_number(), seconds :: non_neg_integer()) ::
          Command.t()
  def make_nack_waiting_response(seq_number, delay_in_seconds) do
    {:ok, command} =
      new(
        seq_number: seq_number,
        flag: :nack_waiting,
        header_extensions: [{:expected_delay, delay_in_seconds}]
      )

    command
  end

  @doc """
  Get the extension by extension name
  """
  @spec extension(Command.t(), atom(), any()) :: any()
  def extension(command, extension_name, default \\ nil) do
    extensions = Command.param!(command, :header_extensions)

    Enum.find_value(extensions, default, fn
      {^extension_name, extension_value} -> extension_value
      _ -> false
    end)
  end

  @spec with_zwave_command(Command.t(), ZWave.seq_number(), [param()]) :: {:ok, Command.t()}
  def with_zwave_command(zwave_command, seq_number, params \\ []) do
    params =
      [flag: :ack_request]
      |> Keyword.merge(params)
      |> Keyword.merge(command: zwave_command, seq_number: seq_number)

    new(params)
  end

  @spec command_name(Command.t()) :: atom() | nil
  def command_name(command) do
    case Command.param(command, :command) do
      nil -> nil
      zwave_command -> zwave_command.name
    end
  end

  defp bit_to_bool(1), do: true
  defp bit_to_bool(0), do: false

  # only add header extensions bytes when there are some
  defp maybe_add_header_extensions(binary_packet, []), do: binary_packet

  defp maybe_add_header_extensions(binary_packet, extensions) do
    header_extensions_bin = header_extensions_to_binary(extensions)
    header_extensions_size = byte_size(header_extensions_bin) + 1

    # add one to the header extension length byte because that byte is the length
    # for all the header extensions plus itself
    binary_packet <> <<header_extensions_size>> <> header_extensions_bin
  end

  defp maybe_add_command(binary_packet, nil), do: binary_packet
  defp maybe_add_command(binary_packet, command), do: binary_packet <> Command.to_binary(command)

  defp meta_from_byte(byte) do
    <<header?::size(1), cmd?::size(1), more_info?::size(1), secure?::size(1), _::size(4)>> =
      <<byte>>

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

  defp parse_command(_, %{cmd: false}), do: {:ok, nil}

  defp parse_command(<<header_extension_length, rest::binary>>, %{cmd: true, header: true}) do
    # Subtract one because the field includes itself thus leading to
    # pulling out the command class byte along with the header extension
    header_extension_length = header_extension_length - 1
    <<_extensions::binary-size(header_extension_length), command_binary::binary>> = rest

    if command_binary == "" do
      {:ok, nil}
    else
      Decoder.from_binary(command_binary)
    end
  end

  defp parse_command(command_binary, %{cmd: true, header: false}) do
    if command_binary == "" do
      {:ok, nil}
    else
      Decoder.from_binary(command_binary)
    end
  end

  defp flag_from_byte(flag_byte) do
    case <<flag_byte>> do
      <<0x00>> -> nil
      <<1::size(1), _::size(1), 1::size(1), _::size(5)>> -> :invalid
      <<_::size(1), 1::size(1), 1::size(1), _::size(5)>> -> :invalid
      <<1::size(1), _::size(7)>> -> :ack_request
      <<_::size(1), 1::size(1), _::size(6)>> -> :ack_response
      <<_::size(2), 1::size(1), 1::size(1), _::size(4)>> -> :nack_waiting
      <<_::size(2), 1::size(1), _::size(1), 1::size(1), _::size(3)>> -> :nack_queue_full
      <<_::size(2), 1::size(1), _::size(2), 1::size(1), _::size(2)>> -> :nack_option_error
      <<_::size(2), 1::size(1), _::size(5)>> -> :nack_response
    end
  end

  defp header_extensions_to_binary(header_extensions) do
    HeaderExtensions.to_binary(header_extensions)
  end
end
