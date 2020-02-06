defmodule Grizzly.Transport do
  @moduledoc false

  @callback open(:inet.ip_address(), :inet.port_number()) :: {:ok, :inet.socket()}

  @callback send(:inet.socket(), binary()) :: :ok

  @callback parse_response(any()) :: {:ok, binary()}

  @callback close(:inet.socket()) :: :ok
end
