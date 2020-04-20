defmodule Grizzly.Transport do
  @moduledoc false

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.Commands.ZIPPacket

  @type socket :: :ssl.sslsocket() | :inet.socket()

  @callback open(:inet.ip_address(), :inet.port_number()) ::
              {:ok, socket()} | {:error, :timeout}

  @callback send(socket(), binary()) :: :ok

  @callback parse_response(any()) ::
              {:ok, ZIPPacket.t() | Command.t()} | {:error, DecodeError.t()}

  @callback close(socket()) :: :ok
end
