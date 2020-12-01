defmodule Grizzly.Transport do
  @moduledoc """
  Behaviour and functions for communicating to `zipgateway`
  """

  defmodule Response do
    @moduledoc """
    The response from parse response
    """

    alias Grizzly.ZWave.Command

    @type t() :: %__MODULE__{
            port: :inet.port_number() | nil,
            ip_address: :inet.ip_address() | nil,
            command: Command.t()
          }

    @enforce_keys [:command]
    defstruct port: nil, ip_address: nil, command: nil
  end

  alias Grizzly.ZWave.{Command, DecodeError}

  @opaque t() :: %__MODULE__{impl: module(), assigns: map()}

  @type socket() :: :ssl.sslsocket() | :inet.socket()

  @type args() :: [
          ip_address: :inet.ip_address(),
          port: :inet.port_number()
        ]

  @type parse_opt() :: {:raw, boolean()}

  @typedoc """
  After starting a server options can be passed back to the caller so that the
  caller can do any other work it might seem fit.

  Options:

    * - `:strategy` - this informs the caller if the transport needs to wait for
        connects to accept or if the socket can just process incoming messages.
        If the strategy is `:accept` that is to mean the socket is okay to start
        accepting new connections.
  """
  @type listen_option() :: {:strategy, :none | :accept}

  @enforce_keys [:impl]
  defstruct assigns: %{}, impl: nil

  @callback open(keyword()) :: {:ok, t()} | {:error, :timeout}

  @callback listen(t()) :: {:ok, t(), [listen_option()]} | {:error, any()}

  @callback accept(t()) :: {:ok, t()} | {:error, any()}

  @callback handshake(t()) :: {:ok, t()} | {:error, any()}

  @callback send(t(), binary(), keyword()) :: :ok

  @callback parse_response(any(), [parse_opt()]) ::
              {:ok, Response.t() | binary() | :connection_closed} | {:error, DecodeError.t()}

  @callback close(t()) :: :ok

  @doc """
  Make a new `Grizzly.Transport`

  If need to optionally assign some priv data you can map that into this function.
  """
  @spec new(module(), map()) :: t()
  def new(impl, assigns \\ %{}) do
    %__MODULE__{
      impl: impl,
      assigns: assigns
    }
  end

  @doc """
  Update the assigns with this field and value
  """
  @spec assigns(t(), atom(), any()) :: t()
  def assigns(transport, assign, assign_value) do
    new_assigns = Map.put(transport.assigns, assign, assign_value)

    %__MODULE__{transport | assigns: new_assigns}
  end

  @doc """
  Get the assign value for the field
  """
  @spec assign(t(), atom(), any()) :: any()
  def assign(transport, assign, default \\ nil),
    do: Map.get(transport.assigns, assign, default)

  @doc """
  Listen using a transport
  """
  @spec listen(t()) :: {:ok, t(), [listen_option()]} | {:error, any()}
  def listen(transport) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.listen(transport)
  end

  @doc """
  Accept a new connection
  """
  @spec accept(t()) :: {:ok, t()} | {:error, any()}
  def accept(transport) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.accept(transport)
  end

  @doc """
  Preform the handshake
  """
  @spec handshake(t()) :: {:ok, t()} | {:error, any()}
  def handshake(transport) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.handshake(transport)
  end

  @doc """
  Open the transport
  """
  @spec open(module(), args()) :: {:ok, t()} | {:error, :timeout}
  def open(transport_module, args) do
    transport_module.open(args)
  end

  @doc """
  Send binary data using a transport
  """
  @spec send(t(), binary(), keyword()) :: :ok
  def send(transport, binary, opts \\ []) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.send(transport, binary, opts)
  end

  @doc """
  Parse the response for the transport
  """
  @spec parse_response(t(), any()) ::
          {:ok, Response.t() | binary() | :connection_closed} | {:error, DecodeError.t()}
  def parse_response(transport, response, opts \\ []) do
    %__MODULE__{impl: transport_impl} = transport

    transport_impl.parse_response(response, opts)
  end
end
