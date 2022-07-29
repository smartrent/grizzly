defmodule Grizzly.Inclusions.NetworkAdapter do
  @moduledoc """
  Behaviour for inclusions to use to talk to the network
  """

  alias Grizzly.{Inclusions, InclusionServer}
  alias Grizzly.ZWave.{DSK, Security}

  @typedoc """
  A module that implements the behaviour
  """
  @type t() :: module()

  @type state() :: term()

  @doc """
  Initialize the adapter
  """
  @callback init() :: {:ok, state()}

  @doc """
  Establish any a connection the including device id
  """
  @callback connect(Grizzly.ZWave.node_id()) :: :ok

  @doc """
  Start the inclusion process
  """
  @callback add_node(state(), [Inclusions.opt()]) :: {:ok, state()}

  @doc """
  Stop an inclusion process
  """
  @callback add_node_stop(state()) :: {:ok, state()}

  @doc """
  Start the exclusion process
  """
  @callback remove_node(state(), [Inclusions.opt()]) :: {:ok, state()}

  @doc """
  Stop the exclusion process
  """
  @callback remove_node_stop(state()) :: {:ok, state()}

  @doc """
  Set the controller into learn mode
  """
  @callback learn_mode(state(), [Inclusions.opt()]) :: {:ok, state()}

  @doc """
  Stop the controller from being in learn mode
  """
  @callback learn_mode_stop(state()) :: {:ok, state()}

  @doc """
  Grant the S2 keys allowed for the including device
  """
  @callback grant_s2_keys([Security.key()], state()) :: {:ok, state()}

  @doc """
  Set the input DSK for the including device
  """
  @callback set_input_dsk(DSK.t(), non_neg_integer(), state()) :: {:ok, state()}

  @doc """
  Handle when a command times out

  This function returns the new status of the inclusion server
  """
  @callback handle_timeout(InclusionServer.status(), reference(), state()) ::
              {InclusionServer.status(), state()}
end
