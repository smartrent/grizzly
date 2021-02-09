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
  """
  @spec new(binary()) :: t()
  def new(dsk_binary) when byte_size(dsk_binary) <= 16 and is_even(byte_size(dsk_binary)) do
    %__MODULE__{raw: dsk_binary}
  end

  @doc """
  Parse a textual representation of a DSK
  """
  @spec parse(dsk_string()) :: {:ok, t()} | {:error, :invalid_dsk}
  def parse(dsk_string) do
    do_parse(dsk_string, <<>>)
  end

  defp do_parse(<<>>, parts) when parts != <<>> and byte_size(parts) <= 16 do
    {:ok, %__MODULE__{raw: parts}}
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
    |> Enum.map(fn b -> String.slice("00000" <> "#{b}", -5, 5) end)
    |> Enum.join(delimiter)
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

  defimpl String.Chars do
    @moduledoc false
    defdelegate to_string(v), to: Grizzly.ZWave.DSK
  end

  defimpl Inspect do
    import Inspect.Algebra
    alias Grizzly.ZWave.DSK

    @moduledoc false

    @spec inspect(DSK.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
    def inspect(v, _opts) do
      concat(["#DSK<#{to_string(v)}>"])
    end
  end
end
