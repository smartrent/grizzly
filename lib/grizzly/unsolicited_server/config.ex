defmodule Grizzly.UnsolicitedServer.Config do
  @type t :: %__MODULE__{
          ip_version: :inet | :inet6,
          ip_address: :inet.ip_address()
        }

  defstruct ip_version: :inet,
            ip_address: {127, 0, 0, 1}

  @spec new(opts :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
