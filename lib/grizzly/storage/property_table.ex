defmodule Grizzly.Storage.PropertyTable do
  @moduledoc """
  A storage adapter for `PropertyTable`.
  """
  @behaviour Grizzly.Storage.Adapter

  @impl Grizzly.Storage.Adapter
  defdelegate put(table, key, value), to: PropertyTable

  @impl Grizzly.Storage.Adapter
  defdelegate put_many(table, properties), to: PropertyTable

  @impl Grizzly.Storage.Adapter
  defdelegate get(table, key), to: PropertyTable

  @impl Grizzly.Storage.Adapter
  defdelegate match(table, pattern), to: PropertyTable

  @impl Grizzly.Storage.Adapter
  defdelegate delete_matches(table, pattern), to: PropertyTable
end
