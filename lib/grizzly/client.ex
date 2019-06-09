defmodule Grizzly.Client do
  @moduledoc false

  alias Grizzly.Packet

  @type socket ::
          :inet.socket()
          | :ssl.sslsocket()
          | pid
          | port

  @type handle_response_result ::
          {:ok, :continue}
          | {:ok, :done, any}
          | {:ok, :heart_beat}
          | {:error, any}

  @enforce_keys [:module, :ip_address, :port]
  defstruct module: nil, ip_address: nil, port: nil, socket: nil

  def new(module, ip_address, port) do
    %__MODULE__{module: module, ip_address: ip_address, port: port}
  end

  @callback connect(ip_address :: :inet.socket_address(), port :: :inet.port_number()) ::
              {:ok, socket}
            when socket: socket

  @callback send(conn :: socket, message :: binary, opts :: keyword) :: :ok

  @callback parse_response(term) :: {:ok, Packet.t() | :heart_beat} | {:error, term}

  @callback send_heart_beat(socket :: socket, opts :: keyword) :: :ok

  @callback close(socket :: socket) :: :ok
end
