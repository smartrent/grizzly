defmodule Grizzly.ZWave.SmartStart.MetaExtension.NameInformation do
  @moduledoc """
  This extension is used to advertise the name assigned to the supporting node

  The name string cannot contain underscores and cannot end with a dash.

  A node's name cannot be more than 62 bytes.
  """
  @behaviour Grizzly.ZWave.SmartStart.MetaExtension

  @type t :: %__MODULE__{
          name: String.t()
        }

  defstruct name: nil

  @spec new(String.t()) ::
          {:ok, t()} | {:error, :contains_underscore | :ends_with_dash | :name_too_long}
  def new(name) do
    case validate_name(name) do
      :ok ->
        {:ok, %__MODULE__{name: name}}

      error ->
        error
    end
  end

  @doc """
  Make a `NameInformation.t()` into a binary
  """
  @impl true
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{name: name}) do
    name_bin = name_to_binary(name)
    {:ok, <<0x64, byte_size(name_bin)>> <> name_bin}
  end

  @doc """
  Make a `NameInformation.t()` from a binary

  If the name contains characters that are not valid this function will return
  `{:error, reason}` where `reason` is:

  - `:contains_underscore`
  - `:ends_with_dash`
  - `:name_too_long`

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
             | :name_too_long
             | :invalid_binary}
  def from_binary(<<0x32::size(7), 0x00::size(1), _length, name::binary>>) do
    name_string =
      name
      |> to_string()
      |> String.replace("\\", "")

    case validate_name(name_string) do
      :ok -> {:ok, %__MODULE__{name: name_string}}
      error -> error
    end
  end

  def from_binary(<<0x32::size(7), 0x01::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  def from_binary(_), do: {:error, :invalid_binary}

  defp validate_name(name) when byte_size(name) < 63 do
    with :ok <- contains_underscore?(name),
         :ok <- ensure_no_dash_at_end(name) do
      :ok
    end
  end

  defp validate_name(_name) do
    {:error, :name_too_long}
  end

  defp contains_underscore?(name) do
    if String.contains?(name, "_") do
      {:error, :contains_underscore}
    else
      :ok
    end
  end

  defp ensure_no_dash_at_end(name) do
    if String.ends_with?(name, "-") do
      {:error, :ends_with_dash}
    else
      :ok
    end
  end

  defp name_to_binary(name) do
    name_list =
      name
      |> String.codepoints()
      |> Enum.reduce([], fn
        ".", nl ->
          nl ++ ["\\", "."]

        c, nl ->
          nl ++ [c]
      end)

    :erlang.list_to_binary(name_list)
  end
end
