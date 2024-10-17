defmodule Grizzly.ZWave.DSK do
  @moduledoc """
  Module for working with the SmartStart and S2 DSKs
  """

  import Integer, only: [is_even: 1]

  defstruct raw: <<>>

  @type t() :: %__MODULE__{raw: <<_::128>>}

  @typedoc """
  The DSK string is the string version of the DSK

  The general format is `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`

  That is 8 blocks of 16 bit integers separated by a dash.

  An example of this would be `50285-18819-09924-30691-15973-33711-04005-03623`
  """
  @type dsk_string :: <<_::376>>

  @typedoc """
  The DSK binary is the elixir binary string form of the DSK

  The format is `<<b1, b2, b3, ... b16>>`

  That is 16 bytes.

  An example of this would be:

  ```elixir
  <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>
  ```
  """
  @type dsk_binary :: <<_::128>>

  @doc """
  Make a new DSK

  If less than 16 bytes are passed in, the rest are initialized to zero.
  Due to how DSKs are constructed, odd length binaries aren't allowed since
  they should never be possible.
  """
  @spec new(binary()) :: t()
  def new(dsk_binary) when byte_size(dsk_binary) == 16 do
    %__MODULE__{raw: dsk_binary}
  end

  def new(dsk_binary) when byte_size(dsk_binary) < 16 and is_even(byte_size(dsk_binary)) do
    new(dsk_binary <> <<0::16>>)
  end

  @doc """
  Parse a textual representation of a DSK
  """
  @spec parse(dsk_string()) :: {:ok, t()} | {:error, :invalid_dsk}
  def parse(dsk_string) do
    do_parse(dsk_string, <<>>)
  end

  @doc """
  Same as `parse/1` but raises an ArgumentError if the DSK is invalid.
  """
  @spec parse!(dsk_string()) :: t() | no_return()
  def parse!(dsk_string) do
    case parse(dsk_string) do
      {:ok, dsk} -> dsk
      {:error, :invalid_dsk} -> raise ArgumentError, "Invalid DSK"
    end
  end

  defp do_parse(<<>>, parts) when parts != <<>> and byte_size(parts) <= 16 do
    {:ok, new(parts)}
  end

  defp do_parse(<<sep, rest::binary>>, parts) when sep in [?-, ?\s] do
    do_parse(rest, parts)
  end

  defp do_parse(<<s::5-bytes, rest::binary>>, parts) do
    case Integer.parse(s) do
      {v, ""} when v < 65536 ->
        do_parse(rest, parts <> <<v::16>>)

      _anything_else ->
        {:error, :invalid_dsk}
    end
  end

  defp do_parse(_anything_else, _parts) do
    {:error, :invalid_dsk}
  end

  @doc """
  Parse a DSK PIN

  PINs can also be parsed by `parse/1`. When working with PINs, though, it's
  nice to be more forgiving and accept PINs as integers or strings without
  leading zeros.

  String examples:

  ```
  iex> {:ok, dsk} = DSK.parse_pin("12345"); dsk
  #DSK<12345-00000-00000-00000-00000-00000-00000-00000>


  iex> {:ok, dsk} = DSK.parse_pin("123"); dsk
  #DSK<00123-00000-00000-00000-00000-00000-00000-00000>
  ```

  Integer examples:

  ```
  iex> {:ok, dsk} = DSK.parse_pin(12345); dsk
  #DSK<12345-00000-00000-00000-00000-00000-00000-00000>

  iex> {:ok, dsk} = DSK.parse_pin(123); dsk
  #DSK<00123-00000-00000-00000-00000-00000-00000-00000>
  ```
  """
  @spec parse_pin(String.t() | non_neg_integer()) :: {:ok, t()} | {:error, :invalid_dsk}

  def parse_pin(string) when is_binary(string) do
    case Integer.parse(string) do
      {pin, ""} -> parse_pin(pin)
      _ -> {:error, :invalid_dsk}
    end
  end

  def parse_pin(pin) when pin >= 0 and pin < 65536 do
    {:ok, new(<<pin::16>>)}
  end

  def parse_pin(_other), do: {:error, :invalid_dsk}

  @doc """
  Convert the DSK to a string

  ```
  iex> {:ok, dsk} = DSK.parse("50285-18819-09924-30691-15973-33711-04005-03623")
  iex> DSK.to_string(dsk)
  "50285-18819-09924-30691-15973-33711-04005-03623"

  iex> {:ok, dsk} = DSK.parse("50285-18819-09924-30691-15973-33711-04005-03623")
  iex> DSK.to_string(dsk, delimiter: "")
  "5028518819099243069115973337110400503623"
  ```

  Options:

    * `:delimiter` - character to join the 5 byte sections together (default `"-"`)
  """
  @spec to_string(t(), keyword()) :: String.t()
  def to_string(%__MODULE__{raw: raw}, opts \\ []) do
    delimiter = Keyword.get(opts, :delimiter, "-")

    for(<<b::16 <- raw>>, do: b)
    |> Enum.map_join(delimiter, &int_to_five_digits/1)
  end

  @doc """
  Return the first five digits of a DSK for use as a PIN

  ```
  iex> {:ok, dsk} = DSK.parse("50285-18819-09924-30691-15973-33711-04005-03623")
  iex> DSK.to_pin_string(dsk)
  "50285"

  iex> {:ok, dsk} = DSK.parse("00001-18819-09924-30691-15973-33711-04005-03623")
  iex> DSK.to_pin_string(dsk)
  "00001"
  ```
  """
  @spec to_pin_string(t()) :: String.t()
  def to_pin_string(%__MODULE__{raw: <<b::16, _::112>>}) do
    int_to_five_digits(b)
  end

  defp int_to_five_digits(b) do
    String.slice("00000" <> "#{b}", -5, 5)
  end

  @doc """
  Take a string representation of the DSK and change it into the
  binary representation
  """
  @spec string_to_binary(dsk_string()) :: {:ok, dsk_binary()} | {:error, :invalid_dsk}
  @deprecated "Use DSK.parse/1 instead"
  def string_to_binary(dsk_string) do
    case parse(dsk_string) do
      {:ok, dsk} -> {:ok, dsk.raw}
      error -> error
    end
  end

  @doc """
  Take a binary representation of the DSK and change it into the
  string representation
  """
  @spec binary_to_string(dsk_binary()) :: {:ok, dsk_string()}
  def binary_to_string(dsk_binary) do
    dsk_string =
      dsk_binary
      |> new()
      |> __MODULE__.to_string()

    {:ok, dsk_string}
  end

  @doc """
  Generate a DSK that is all zeros

  This is useful for placeholder/default DSKs.
  """
  @spec zeros() :: t()
  def zeros() do
    %__MODULE__{
      raw: <<0::size(16)-unit(8)>>
    }
  end

  @doc """
  Extracts the NWI Home ID (the Home ID used by a SmartStart device when it is
  not yet included in a network) from the DSK.

  The NWI Home ID is calculated by taking bytes 9-12 of the DSK. Given this value,
  the two most significant bits are then set and the least significant bit is cleared.
  """
  @spec nwi_home_id(t()) :: non_neg_integer()
  def nwi_home_id(%__MODULE__{raw: <<_::8-bytes, _::2, dsk_bits::29, _::1, _::binary>>}) do
    <<nwi_home_id::32>> = <<1::1, 1::1, dsk_bits::29, 0::1>>
    nwi_home_id
  end

  defimpl String.Chars do
    @moduledoc false
    defdelegate to_string(v), to: Grizzly.ZWave.DSK
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias Grizzly.ZWave.DSK

    @moduledoc false

    @spec inspect(DSK.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
    def inspect(v, opts) do
      concat(["#DSK<", color(string(to_string(v)), :string, opts), ">"])
    end
  end
end
