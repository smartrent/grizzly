defmodule Grizzly.VirtualDevices.Device do
  @moduledoc """
  Behaviour for implementing virtual device specifics
  """

  alias Grizzly.ZWave.{Command, DeviceClass}

  @typedoc """
  A module that implements this behaviour
  """
  @type t() :: module()

  @doc """
  Initialize the device
  """
  @callback init() :: {:ok, state :: term(), DeviceClass.t()} | {:error, term()}

  @doc """
  Handle a Z-Wave command
  """
  @callback handle_command(Command.t(), state :: term()) ::
              {:ok, Command.t(), state :: term()} | {:error, term()}
end
