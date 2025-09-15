defmodule Grizzly.Storage.Adapter do
  @moduledoc """
  Behaviour for Grizzly storage adapters.

  Implementations should be compatible with `PropertyTable`.
  """

  alias Grizzly.Storage

  @typedoc """
  The argument passed to the storage adapter. See `Grizzly.Options`.
  """
  @type adapter_options :: any()

  @doc """
  Put a key-value pair into storage.
  """
  @callback put(adapter_options(), Storage.key(), Storage.value()) :: :ok

  @doc """
  Put multiple key-value pairs into storage.
  """
  @callback put_many(adapter_options(), [{Storage.key(), Storage.value()}]) :: :ok

  @doc """
  Get a value from storage by key.
  """
  @callback get(adapter_options(), Storage.key()) :: Storage.value()

  @doc """
  Match keys in storage against a pattern.
  """
  @callback match(adapter_options(), Storage.pattern()) :: [{Storage.key(), Storage.value()}]

  @doc """
  Delete keys matching a pattern.
  """
  @callback delete_matches(adapter_options(), Storage.pattern()) :: :ok
end
