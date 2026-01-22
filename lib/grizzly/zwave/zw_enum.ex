defmodule Grizzly.ZWave.ZWEnum do
  @moduledoc """
  A bidirectional map for Z-Wave enumerations.
  """

  @type k :: atom()
  @type v :: non_neg_integer()

  @type t() :: %__MODULE__{
          keys: %{optional(atom()) => non_neg_integer()},
          values: %{optional(non_neg_integer()) => atom()}
        }

  defstruct keys: %{}, values: %{}

  @doc """
  Creates a new empty `ZWEnum`.
  """
  @spec new() :: t()
  def new(), do: %__MODULE__{}

  @doc """
  Creates a new `ZWEnum` from an enumerable of `{key, value}` pairs.
  """
  @spec new(Enum.t()) :: t()
  def new(enumerable)

  def new(%__MODULE__{} = enum), do: enum

  def new(enum) do
    Enum.reduce(enum, new(), fn {k, v}, acc -> put(acc, k, v) end)
  end

  @doc """
  Creates a new `ZWEnum` from an enumerable, transforming each item with the
  provided function.

  ## Examples

      iex> enum = new([:a, :b, :c], fn item -> {item, Atom.to_string(item)} end)
      iex> to_list(enum) |> Enum.sort()
      [a: "a", b: "b", c: "c"]
  """
  @spec new(Enum.t(), (term() -> {k(), v()})) :: t()
  def new(enum, transform) do
    Enum.reduce(enum, new(), fn item, acc ->
      {k, v} = transform.(item)
      put(acc, k, v)
    end)
  end

  @doc """
  Returns the number of key-value pairs in the enum.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> size(enum)
      2
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{keys: keys}), do: map_size(keys)

  @doc """
  Returns a list of all keys in the enum.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> keys(enum) |> Enum.sort()
      [:a, :b]
  """
  @spec keys(t()) :: [k()]
  def keys(%__MODULE__{keys: keys}), do: Map.keys(keys)

  @doc """
  Returns a list of all values in the enum.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> values(enum) |> Enum.sort()
      ["bar", "foo"]
  """
  @spec values(t()) :: [v()]
  def values(%__MODULE__{values: values}), do: Map.keys(values)

  @doc """
  Checks if the enum has the given key.
  """
  @spec has_key?(t(), k()) :: boolean()
  def has_key?(%__MODULE__{keys: keys}, k), do: Map.has_key?(keys, k)

  @doc """
  Checks if two enums are equal.
  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(%__MODULE__{keys: keys1}, %__MODULE__{keys: keys2}), do: Map.equal?(keys1, keys2)

  @doc """
  Gets the value for the given key.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> get(enum, :a)
      "foo"
      iex> get(enum, :c, "default")
      "default"
  """
  @spec get(t(), k(), v() | nil) :: v() | nil
  def get(enum, key, default \\ nil)
  def get(%__MODULE__{keys: keys}, k, default), do: Map.get(keys, k, default)

  @doc """
  Gets the key for the given value.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> get_key(enum, "foo")
      :a
      iex> get_key(enum, "baz", :default)
      :default
  """
  @spec get_key(t(), v(), k()) :: k() | nil
  def get_key(enum, value, default \\ nil)
  def get_key(%__MODULE__{values: values}, v, default), do: Map.get(values, v, default)

  @doc """
  Gets the value represented by the given key.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> fetch(enum, :a)
      {:ok, "foo"}
      iex> fetch(enum, :c)
      :error
  """
  @spec fetch(t(), k()) :: {:ok, v()} | :error
  def fetch(%__MODULE__{keys: keys}, k) do
    case Map.fetch(keys, k) do
      :error -> :error
      {:ok, v} -> {:ok, v}
    end
  end

  @doc """
  Gets the value represented by the given key, raising if the key is not found.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> fetch!(enum, :a)
      "foo"
      iex> fetch!(enum, :c)
      ** (KeyError) key :c not found in: ZWEnum.new([a: "foo", b: "bar"])
  """
  @spec fetch!(t(), k()) :: v()
  def fetch!(enum, k) do
    case fetch(enum, k) do
      {:ok, v} -> v
      :error -> raise KeyError, "key #{inspect(k)} not found in: #{inspect(enum)}"
    end
  end

  @doc """
  Alias for `fetch/2`.
  """
  @spec encode(t(), k()) :: {:ok, v()} | :error
  def encode(enum, k), do: fetch(enum, k)

  @doc """
  Alias for `fetch!/2`.
  """
  @spec encode!(t(), k()) :: v()
  def encode!(enum, k), do: fetch!(enum, k)

  @doc """
  Gets the key represented by the given value.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> fetch_key(enum, "foo")
      {:ok, :a}
      iex> fetch_key(enum, "baz")
      :error
  """
  @spec fetch_key(t(), v()) :: {:ok, k()} | :error
  def fetch_key(%__MODULE__{values: values}, v) do
    case Map.fetch(values, v) do
      :error -> :error
      {:ok, k} -> {:ok, k}
    end
  end

  @doc """
  Gets the key represented by the given value, raising if the value is not found.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> fetch_key!(enum, "foo")
      :a
      iex> fetch_key!(enum, "baz")
      ** (KeyError) value "baz" not found in: ZWEnum.new([a: "foo", b: "bar"])
  """
  @spec fetch_key!(t(), v()) :: k()
  def fetch_key!(enum, v) do
    case fetch_key(enum, v) do
      {:ok, k} -> k
      :error -> raise KeyError, "value #{inspect(v)} not found in: #{inspect(enum)}"
    end
  end

  @doc """
  Alias for `fetch_key/2`.
  """
  @spec decode(t(), v()) :: {:ok, k()} | :error
  def decode(enum, v), do: fetch_key(enum, v)

  @doc """
  Alias for `fetch_key!/2`.
  """
  @spec decode!(t(), v()) :: k()
  def decode!(enum, v), do: fetch_key!(enum, v)

  @doc """
  Inserts the given `{key, value}` pair into the enum.

  ## Examples

      iex> enum = new()
      iex> enum = put(enum, :a, "foo")
      iex> enum = put(enum, :b, "bar")
      iex> to_list(enum) |> Enum.sort()
      [a: "foo", b: "bar"]
  """
  @spec put(t(), k(), v()) :: t()
  def put(%__MODULE__{keys: keys, values: values} = enum, k, v) do
    %__MODULE__{
      enum
      | keys: Map.put(keys, k, v),
        values: Map.put(values, v, k)
    }
  end

  @doc """
  Converts the enum to a list of `{key, value}` pairs.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> to_list(enum) |> Enum.sort()
      [a: "foo", b: "bar"]
  """
  @spec to_list(t()) :: [{k(), v()}]
  def to_list(%__MODULE__{keys: keys}) do
    Map.to_list(keys)
  end

  @doc """
  Convenience shortcut for `member?/3`.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> member?(enum, {:a, "foo"})
      true
      iex> member?(enum, {:a, "bar"})
      false
  """
  @spec member?(t(), {k(), v()}) :: boolean()
  def member?(enum, kv)
  def member?(enum, {key, value}), do: member?(enum, key, value)

  @doc """
  Checks if `enum` contains `{key, value}` pair.

  ## Examples

      iex> enum = new([a: "foo", b: "bar"])
      iex> member?(enum, :a, "foo")
      true
      iex> member?(enum, :a, "bar")
      false
  """
  @spec member?(t(), k(), v()) :: boolean()
  def member?(enum, key, value)

  def member?(%__MODULE__{keys: keys}, key, value) do
    Map.has_key?(keys, key) and keys[key] === value
  end

  defimpl Enumerable do
    alias Grizzly.ZWave.ZWEnum

    def reduce(enum, acc, fun) do
      Enumerable.List.reduce(ZWEnum.to_list(enum), acc, fun)
    end

    def member?(enum, val) do
      {:ok, ZWEnum.member?(enum, val)}
    end

    def count(enum) do
      {:ok, ZWEnum.size(enum)}
    end

    def slice(_enum) do
      {:error, __MODULE__}
    end
  end

  defimpl Collectable do
    alias Grizzly.ZWave.ZWEnum

    def into(original) do
      {original,
       fn
         enum, {:cont, {k, v}} -> ZWEnum.put(enum, k, v)
         enum, :done -> enum
         _, :halt -> :ok
       end}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    alias Grizzly.ZWave.ZWEnum

    def inspect(enum, opts) do
      concat(["ZWEnum.new(", to_doc(ZWEnum.to_list(enum), opts), ")"])
    end
  end
end
