defmodule Grizzly.ZWave.DSK do
  @moduledoc """
  Module for working with the SmartStart and S2 DSKs
  """

  @typedoc """
  The DSK string is the string version of the DSK

  The general format is `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`

  That is 8 blocks of 16 bit integers separated by a dash.

  An example of this would be `50285-18819-09924-30691-15973-33711-04005-03623`
  """
  @type dsk_string :: String.t()

  @typedoc """
  The DSK binary is the elixir binary string form of the DSK

  The format is `<<b1, b2, b3, ... b16>>`

  That is 16 bytes.

  An example of this would be:

  ```elixir
  <<196, 109, 73, 131, 38, 196, 119, 227, 62, 101, 131, 175, 15, 165, 14, 39>>
  ```
  """
  @type dsk_binary :: binary()

  @doc """
  Take a string representation of the DSK and change it into the
  binary representation
  """
  @spec string_to_binary(dsk_string()) ::
          {:ok, dsk_binary()} | {:error, :dsk_too_short | :dsk_too_long}
  def string_to_binary(dsk_string) when byte_size(dsk_string) > 47, do: {:error, :dsk_too_long}
  def string_to_binary(dsk_string) when byte_size(dsk_string) < 47, do: {:error, :dsk_too_short}

  def string_to_binary(dsk_string) do
    dsk_binary =
      dsk_string
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)
      |> Enum.reduce(<<>>, fn dsk_number, binary ->
        binary <> <<dsk_number::size(16)>>
      end)

    {:ok, dsk_binary}
  end

  @doc """
  Take a binary representation of the DSK and change it into the
  string representation
  """
  @spec binary_to_string(dsk_binary()) ::
          {:ok, dsk_string()} | {:error, :dsk_too_short | :dsk_too_long}
  def binary_to_string(dsk_binary) when byte_size(dsk_binary) > 16, do: {:error, :dsk_too_long}
  def binary_to_string(dsk_binary) when byte_size(dsk_binary) < 16, do: {:error, :dsk_too_short}

  def binary_to_string(dsk_binary) do
    dsk_string =
      for(<<b::16 <- dsk_binary>>, do: b)
      |> Enum.map(fn b -> String.slice("00000" <> "#{b}", -5, 5) end)
      |> Enum.join("-")

    {:ok, dsk_string}
  end
end
