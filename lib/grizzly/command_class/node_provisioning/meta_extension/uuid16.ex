defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.UUID16 do
  @moduledoc """
  This is used to advertise 16 bytes of manufactured-defined information that
  is unique for a given product.

  Z-Wave UUIDs are not limited to the format outlined in RFC 4122 but can also
  be ASCII characters and a relevant prefix.
  """

  @typedoc """
  The three formats that the Z-Wave UUID can be formatted in are `:ascii`,
  `:hex`, or `:rfc4122`.

  Both `:ascii` and `:hex` can also have the prefix `sn:` or `UUID:`.

  Valid `:hex` formatted UUIDs look like:

  - `0102030405060708090A141516171819`
  - `sn:0102030405060708090A141516171819`
  - `UUID:0102030405060708090A141516171819`

  Valid `:ascii` formatted UUIDs look like:

  - `Hello Elixir!!!`
  - `sn:Hello Elixir!!!`
  - `UUID:Hello Elixir!!!`


  Lastly `rfc4122` format looks like `58D5E212-165B-4CA0-909B-C86B9CEE0111`
  where every two digits make up one hex value.

  More information about RFC 4122 and the specification format can be
  found [here](https://tools.ietf.org/html/rfc4122#section-4.1.2).
  """
  @type format :: :ascii | :hex | :rfc4122

  @type t :: %__MODULE__{
          uuid: String.t(),
          format: format()
        }

  defstruct uuid: nil, format: nil

  defguardp is_format_hex(value) when value in [0, 2, 4]
  defguardp is_format_ascii(value) when value in [1, 3, 5]
  defguardp is_format_rfc4122(value) when value == 6

  @doc """
  Take a binary string and try to make a `UUID16.t()` from it

  If the critical bit is set in teh binary this will return
  `{:error, :critical_bit_set}` and the information should be ignored.

  If the format in the binary is not part of the defined Z-Wave specification
  this will return `{:error, :invalid_format}`
  """
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :critical_bit_set | :invalid_format}
  def from_binary(<<0x03::size(7), 0x00::size(1), 0x11, presentation_format, uuid::binary>>) do
    with {:ok, uuid_string} <- uuid_from_binary(presentation_format, uuid),
         {:ok, format} <- format_from_byte(presentation_format) do
      {:ok, %__MODULE__{uuid: uuid_string, format: format}}
    end
  end

  def from_binary(<<0x03::size(7), 0x01::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  @doc """
  Make a binary string from a `UUID16.t()`
  """
  @spec to_binary(t()) :: {:ok, binary()} | {:error, :invalid_uuid_length | :invalid_format}
  def to_binary(%__MODULE__{uuid: uuid, format: format})
      when format in [:hex, :ascii, :rfc4122] do
    with {:ok, [format_prefix, uuid]} <- get_format_prefix_and_uuid(uuid),
         {:ok, uuid_binary} <- uuid_to_binary(uuid, format) do
      {:ok, <<0x06, 0x11, format_to_byte(format, format_prefix)>> <> uuid_binary}
    end
  end

  def to_binary(_uuid), do: {:error, :invalid_format}

  defp get_format_prefix_and_uuid(uuid_string) do
    case String.split(uuid_string, ":") do
      [uuid] -> {:ok, [:none, uuid]}
      [prefix, _uuid] = result when prefix in ["sn", "UUID"] -> {:ok, result}
      _ -> {:error, :invalid_uuid_string}
    end
  end

  defp format_from_byte(format_byte) when is_format_hex(format_byte), do: {:ok, :hex}
  defp format_from_byte(format_byte) when is_format_ascii(format_byte), do: {:ok, :ascii}
  defp format_from_byte(format_byte) when is_format_rfc4122(format_byte), do: {:ok, :rfc4122}
  defp format_from_byte(format_byte) when format_byte in 7..99, do: {:ok, :hex}
  defp format_from_byte(_), do: {:error, :invalid_format}

  defp format_to_byte(:hex, :none), do: 0
  defp format_to_byte(:hex, "sn"), do: 2
  defp format_to_byte(:hex, "UUID"), do: 4
  defp format_to_byte(:ascii, :none), do: 1
  defp format_to_byte(:ascii, "sn"), do: 3
  defp format_to_byte(:ascii, "UUID"), do: 5
  defp format_to_byte(:rfc4122, :none), do: 6

  defp uuid_to_binary(uuid, :hex) when byte_size(uuid) == 32 do
    hex_uuid_to_binary(uuid, <<>>)
  end

  defp uuid_to_binary(uuid, :ascii) when byte_size(uuid) == 16 do
    ascii_uuid_to_binary(uuid)
  end

  defp uuid_to_binary(uuid, :rfc4122) when byte_size(uuid) == 36 do
    rfc4122_uuid_to_binary(uuid)
  end

  defp uuid_to_binary(_uuid, _format), do: {:error, :invalid_uuid_length}

  defp rfc4122_uuid_to_binary(uuid) do
    binary_uuid =
      uuid
      |> String.split("-")
      |> Enum.flat_map(&String.split(&1, "", trim: true))
      |> Enum.chunk_every(2)
      |> Enum.map(fn digits ->
        digits
        |> Enum.join("")
        |> String.to_integer(16)
      end)
      |> :erlang.list_to_binary()

    {:ok, binary_uuid}
  end

  defp hex_uuid_to_binary("", binary) do
    {:ok, binary}
  end

  defp hex_uuid_to_binary(uuid, binary) do
    {digit, digits} = String.split_at(uuid, 2)
    byte = String.to_integer(digit, 16)

    hex_uuid_to_binary(digits, binary <> <<byte>>)
  end

  defp ascii_uuid_to_binary(uuid_string) do
    uuid_binary =
      uuid_string
      |> String.split("", trim: true)
      |> Enum.reduce(<<>>, &(&2 <> &1))

    {:ok, uuid_binary}
  end

  defp uuid_as_hex_digits(uuid) do
    hex_digits_as_string(uuid)
  end

  defp uuid_as_ascii(uuid) do
    uuid_out_string =
      uuid
      |> to_charlist()
      |> to_string()

    uuid_out_string
  end

  defp uuid_from_binary(format, uuid) when is_format_hex(format) do
    formatted_uuid = uuid_as_hex_digits(uuid)

    case format do
      0 -> {:ok, formatted_uuid}
      2 -> {:ok, "sn:#{formatted_uuid}"}
      4 -> {:ok, "UUID:#{formatted_uuid}"}
    end
  end

  defp uuid_from_binary(format, uuid) when is_format_ascii(format) do
    formatted_uuid = uuid_as_ascii(uuid)

    case format do
      1 -> {:ok, formatted_uuid}
      3 -> {:ok, "sn:#{formatted_uuid}"}
      5 -> {:ok, "UUID:#{formatted_uuid}"}
    end
  end

  defp uuid_from_binary(
         6,
         <<time_low::binary-size(4), time_mid::binary-size(2),
           time_hi_and_version::binary-size(2), clock_seq::binary-size(2), node::binary-size(6)>>
       ) do
    formatted =
      [
        time_low,
        time_mid,
        time_hi_and_version,
        clock_seq,
        node
      ]
      |> Enum.map(&hex_digits_as_string/1)
      |> Enum.join("-")

    {:ok, formatted}
  end

  defp uuid_from_binary(format, uuid) when format in 7..99 do
    uuid_from_binary(0, uuid)
  end

  defp hex_digits_as_string(binary) do
    list = :erlang.binary_to_list(binary)

    Enum.reduce(list, "", fn integer, uuid_string ->
      if integer < 16 do
        uuid_string <> "0" <> Integer.to_string(integer, 16)
      else
        uuid_string <> Integer.to_string(integer, 16)
      end
    end)
  end
end
