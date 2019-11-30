defmodule Grizzly.Conn.Config do
  @moduledoc """
  A data structure to configure the connection between
  the library and the Z/IP server.

  Each connection will take on of these to know how to
  get connected and which client to use to do connecting
  and response handling.

  By default, if there is no client given, this will
  enfore the `Grizzly.Client.DTLS` is used.
  """
  alias Grizzly.Client.DTLS

  @typedoc """
  The configuration is defined as follows:

   * `:port` - the server port.
   * `:ip` - the server IP address.
   * `:client` - the client that will handle connecting and message processing.
   * `:heart_beat_timer` - the interval (in milliseconds) between heart beats.
     This SHOULD be between 25-55 seconds.
   * `:autoconnect` - whether or not the connection should automatically attempt
     to connect on application start.
   * `:mode` - can be `:sync` or `:async`. If `:sync` is set then this will
     block the caller. If `:async` is set then messages with the connection will
     be pushed to the calling process.

  """
  @type t :: %__MODULE__{
          port: :inet.port_number(),
          ip: :inet.ip_address(),
          client: module,
          heart_beat_timer: non_neg_integer,
          autoconnect: boolean,
          mode: mode
        }

  @type mode :: :sync | :async

  @enforce_keys [:ip, :port, :client]
  defstruct port: nil,
            ip: nil,
            client: nil,
            heart_beat_timer: 25_000,
            autoconnect: true,
            mode: :sync

  def new(opts \\ []) do
    opts = Keyword.put_new(opts, :client, DTLS)
    struct(__MODULE__, opts)
  end

  @spec async?(t) :: boolean
  def async?(%__MODULE__{mode: :async}), do: true
  def async?(_), do: false

  def get_mode(%__MODULE__{mode: mode}), do: mode
end
