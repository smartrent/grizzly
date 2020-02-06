defmodule Grizzly.ZWave.SmartStart.MetaExtension.LocationInformation do
  @moduledoc """
  This extension is used to advertise the location assigned to the supporting node

  The location string cannot contain underscores and cannot end with a dash.

  The location string can contain a period (.) but a sublocation cannot end a
  dash. For example:

  ```
  123.123-.123
  ```

  The above location invalid. To make it valid remove the `-` before `.`.

  A node's location cannot be more than 62 bytes.
  """
  @behaviour Grizzly.ZWave.SmartStart.MetaExtension

  @type t :: %__MODULE__{
          location: String.t()
        }

  defstruct location: nil

  @doc """
  Make a new `LocationInformation.t()` from a location string

  If the location contains characters that are not valid this function will return
  `{:error, reason}` where `reason` is:

  - `:contains_underscore`
  - `:ends_with_dash`
  - `:location_too_long`
  - `:sublocation_ends_with_dash`
  """
  @spec new(String.t()) ::
          {:ok, t()}
          | {:error,
             :contains_underscore
             | :ends_with_dash
             | :location_too_long
             | :sublocation_ends_with_dash}
  def new(location) do
    case validate_location(location) do
      :ok ->
        {:ok, %__MODULE__{location: location}}

      error ->
        error
    end
  end

  @doc """
  Make a `LocationInformation.t()` into a binary
  """
  @impl true
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{location: location}) do
    location_bin = location_to_binary(location)
    {:ok, <<0x66, byte_size(location_bin)>> <> location_bin}
  end

  @doc """
  Make a `LocationInformation.t()` from a binary

  If the location contains characters that are not valid this function will return
  `{:error, reason}` where `reason` is:

  - `:contains_underscore`
  - `:ends_with_dash`
  - `:location_too_long`
  - `:sublocation_ends_with_dash`

  If the critical bit set in the binary this function will return
  `{:error, :critical_bit_set}`
  """
  @impl true
  @spec from_binary(binary) ::
          {:ok, t()}
          | {:error,
             :contains_underscore
             | :ends_with_dash
             | :critical_bit_set
             | :location_too_long
             | :sublocation_ends_with_dash
             | :invalid_binary}
  def from_binary(<<0x33::size(7), 0x00::size(1), _length, location::binary>>) do
    location_string =
      location
      |> to_string()

    case validate_location(location_string) do
      :ok -> {:ok, %__MODULE__{location: location_string}}
      error -> error
    end
  end

  def from_binary(<<0x33::size(7), 0x01::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  def from_binary(_), do: {:error, :invalid_binary}

  defp validate_location(location) when byte_size(location) < 63 do
    with :ok <- contains_underscore?(location),
         :ok <- ensure_no_dash_at_end(location),
         :ok <- ensure_no_dash_at_end_of_sublocation(location) do
      :ok
    end
  end

  defp validate_location(_location) do
    {:error, :location_too_long}
  end

  defp ensure_no_dash_at_end_of_sublocation(location) do
    if String.contains?(location, "-.") do
      {:error, :sublocation_ends_with_dash}
    else
      :ok
    end
  end

  defp contains_underscore?(location) do
    if String.contains?(location, "_") do
      {:error, :contains_underscore}
    else
      :ok
    end
  end

  defp ensure_no_dash_at_end(location) do
    if String.ends_with?(location, "-") do
      {:error, :ends_with_dash}
    else
      :ok
    end
  end

  defp location_to_binary(location) do
    location_list =
      location
      |> String.codepoints()

    :erlang.list_to_binary(location_list)
  end
end
