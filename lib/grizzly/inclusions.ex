defmodule Grizzly.Inclusions do
  @moduledoc """
  Docs about adding and removing nodes
  """

  alias Grizzly.Inclusions.InclusionRunnerSupervisor
  alias Grizzly.Inclusions.InclusionRunner
  alias Grizzly.ZWave.Security

  @doc """
  Start the process to add a Z-Wave node to the network
  """
  @spec add_node() :: :ok
  def add_node() do
    case InclusionRunnerSupervisor.start_runner() do
      {:ok, runner} ->
        InclusionRunner.add_node(runner)
    end
  end

  @doc """
  Start the process to remove a Z-Wave node from the network
  """
  @spec remove_node() :: :ok
  def remove_node() do
    case InclusionRunnerSupervisor.start_runner() do
      {:ok, runner} ->
        InclusionRunner.remove_node(runner)
    end
  end

  @doc """
  Tell the inclusion process which keys to use during the inclusion process

  During S2 inclusion the node being included with send a `DSKAddKeysReport`
  to request which keys it can use to included securely. This function is
  useful for passing back to the node which keys it is allowed to use and
  depending on that answer the including node might request more information.
  """
  @spec grant_keys([Security.key()]) :: :ok
  def grant_keys(s2_keys) do
    InclusionRunner.grant_keys(InclusionRunner, s2_keys)
  end

  @doc """
  Tell the inclusion process what the input DSK is

  If the `NodeAddDSKReport`'s `:input_dsk_length` is `0` you can just call this
  function without any arguments:

  ```elixir
  Grizzly.Inclusions.set_input_dsk()
  ```

  If you are doing `:s2_authenticated` or `:s2_access_control` the
  `NodeAddDSKReport` will probably ask for input DSK length of `2`. This means
  it is expecting a 2 byte (16 bit) number, which is normally a 5 digit pin
  located somewhere on the node that is being added. After locating the pin and
  you can pass it as an argument like so:

  ```elixir
  Grizzly.Inclusions.set_input_dsk(12345)
  ```
  """
  @spec set_input_dsk(non_neg_integer()) :: :ok
  def set_input_dsk(input_dsk \\ 0) do
    InclusionRunner.set_dsk(InclusionRunner, input_dsk)
  end

  @doc """
  Stop an add node inclusion process
  """
  @spec add_node_stop() :: :ok
  def add_node_stop() do
    InclusionRunner.add_node(InclusionRunner)
  end

  @doc """
  Stop a remove node inclusion process
  """
  @spec remove_node_stop() :: :ok
  def remove_node_stop() do
    InclusionRunner.remove_node_stop(InclusionRunner)
  end

  @doc """
  Check to see if there is an inclusion process running
  """
  @spec inclusion_running?() :: boolean()
  def inclusion_running?() do
    child_count = DynamicSupervisor.count_children(InclusionRunnerSupervisor)
    child_count.active == 1
  end
end
