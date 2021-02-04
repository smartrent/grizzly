defmodule Grizzly.Inclusions do
  @moduledoc """
  Module for adding and removing Z-Wave nodes

  In Z-Wave the term "inclusions" means two things:

  1. Adding a new Z-Wave device to the Z-Wave Network
  2. Removing a Z-Wave device to the Z-Wave Network

  In practice though it is more common to speak about adding a Z-Wave node in
  the context of "including" and removing an Z-Wave mode in the context of
  "excluding." This module provides functionality for working will all contexts
  of inclusion, both adding and removing.

  ## Adding a Z-Wave Node (including)

  When adding a device that does not required any security  authentication is
  as simple as calling `Grizzly.Inclusions.add_node/0`.

  ```elixir
  iex> Grizzly.Inclusions.add_node()
  :ok
  ```

  After starting the inclusion on the controller, which the above function
  does, you can then put your device into inclusion as well. From here the new
  device and your controller will communicate and if all goes well you should
  receive a message in the form of
  `{:grizzly, :inclusion, NodeAddStatus}` where the the `NodeAddStatus` is a
  Z-Wave command the contains information about the inclusion status (status,
  node id, supported command classes, security levels, etc.). See
  `Grizzly.ZWave.Commands.NodeAddStatus` for more information about the values
  in that command. For example:

  ```elixir
  defmodule MyInclusionServer do
    use GenServer

    require Logger

    alias Grizzly.Inclusions
    alias Grizzly.ZWave.Command

    def start_link(_) do
      GenServer.start_link(__MODULE__, nil)
    end

    def add_node(pid) do
      GenServer.call(pid, :add_node)
    end

    def init(_) do
      {:ok, nil}
    end

    def handle_call(:add_node, _from, state) do
      :ok = Inclusions.add_node()
      {:reply, :ok, state}
    end

    def handle_info({:grizzly, :inclusion, report}, state) do
      case Command.param!(report.command, :status) do
        :done ->
          node_id = Command.param!(report.command, :node_id)
          Logger.info("Node added with id: " <> node_id)

        :failed ->
          Logger.warn("Adding node failed :(")

        :security_failed ->
          node_id = Command.param!(report.command, :node_id)
          Logger.warn("Node added with id: " <> node_id <> "but the security failed")
      end

      {:noreply, state}
    end
  end
  ```
  ### Stop Adding a Node

  If you need you need to stop trying to add a node to the Z-Wave network you
  can use the `Grizzly.Inclusions.remove_node/0` function.

  This should stop the controller from trying to add a node and return it to
  a normal functions state.

  ### Security

  There are five security levels in Z-Wave: unsecured, S0, S2 unauthenticated,
  S2 authenticated, and S2 access control. The first 2 requires nothing
  special from the calling process to able to use, as the controller and the
  including node will figure out which security scheme to use.

  #### S2

  The process of adding an S2 device is a little more involved. The process is
  the same up until right after you put the including node into the inclusion
  mode. At that point including will request security keys, which really means
  it tells you which S2 security scheme it supports. You then use the
  `Grizzly.Inclusions.grant_keys/1` function to pass a list of allowed security
  schemes.

  After that the node will response with a `NodeAddDSKReport` where it reports
  the DSK and something called the `:dsk_input_length`. If the input length is
  `0`, that means it is trying to do S2 unauthenticated inclusion. You can
  just call `Grizzly.Inclusions.set_input_dsk/0` function and the rest of the
  inclusion process should continue until complete.

  If the `:dsk_input_length` has number, normally will be `2` that means the
  including device is requesting a 5 digit digit pin that is normally found on
  a label somewhere on the physical device it.

  From here you can call `Grizzly.Inclusions.set_input_dsk/1` with the 5 digit
  integer as the argument. The inclusion process should continue until complete.

  ## Removing a Z-Wave Node (excluding)

  To remove a Z-Wave node from the network the
  `Grizzly.Inclusions.remove_node/0` will start an inclusion process for removing
  a Z-Wave node. After calling this function you can place your device into the
  inclusion (normally the same way you included the device is the way the device
  is excluded) mode. At the end of the exclusion the `NodeRemoveStatus` command
  is received and can be inspected for success of failure.

  ### Removed Node ID 0?

  Any Z-Wave controller can excluded a device from another controller. In
  practice this means your Z-Wave controller can make a device "forget" the
  controller it is currently attached to. Most the time Z-Wave products will
  have you excluded your device and then included just to make sure the
  including node isn't connected to another Z-Wave controller.

  When this happens you will a successful `NodeRemoveStatusReport` but the node
  id will be `0`. This is consider successful and most the time intend.

  ## Stopping Remove Node Process

  To stop the removal inclusion process on your controller you can call the
  `Grizzly.Inclusions.remove_node_stop/0` function.

  ## Inclusion Handler

  To tie into the inclusion process we default to sending messages to the
  calling process. However, there is a better way to tie into this system.

  When starting any inclusion process you can pass the `:handler` option
  which can be either another pid or a module that implements the
  `Grizzly.InclusionHandler` behaviour, or a tuple with the module and callback arguments.

  A basic implementation might look like:

  ```elixir
  defmodule MyApp.InclusionHandler do
    @behaviour Grizzly.InclusionHandler

    require Logger

    def handle_report(report, opts) do
      Logger.info("Got command: " <> report.command.name <> " with callback arguments " <> inspect opts)
      :ok
    end
  end
  ```

  This is recommended for applications using Grizzly over a `GenServer` that
  wraps `Grizzly.Inclusions`.
  """

  alias Grizzly.Inclusions.InclusionRunnerSupervisor
  alias Grizzly.Inclusions.InclusionRunner
  alias Grizzly.ZWave.{DSK, Security}

  @type opt ::
          {:controller_id, Grizzly.node_id()} | {:handler, pid() | module() | {module, keyword()}}

  @doc """
  Start the process to add a Z-Wave node to the network
  """
  @spec add_node([opt()]) :: :ok
  def add_node(opts \\ []) do
    case InclusionRunnerSupervisor.start_runner(opts) do
      {:ok, runner} ->
        InclusionRunner.add_node(runner)
    end
  end

  @doc """
  Start the process to remove a Z-Wave node from the network
  """
  @spec remove_node([opt()]) :: :ok
  def remove_node(opts \\ []) do
    case InclusionRunnerSupervisor.start_runner(opts) do
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
  {:ok, dsk} = Grizzly.ZWave.DSK.parse("12345")
  Grizzly.Inclusions.set_input_dsk(dsk)
  ```
  """
  @spec set_input_dsk(DSK.t()) :: :ok
  def set_input_dsk(input_dsk \\ DSK.new(<<>>)) do
    InclusionRunner.set_dsk(InclusionRunner, input_dsk)
  end

  @doc """
  Stop an add node inclusion process
  """
  @spec add_node_stop() :: :ok
  def add_node_stop() do
    InclusionRunner.add_node_stop(InclusionRunner)
  end

  @doc """
  Stop a remove node inclusion process
  """
  @spec remove_node_stop() :: :ok
  def remove_node_stop() do
    InclusionRunner.remove_node_stop(InclusionRunner)
  end

  @doc """
  Start learn mode on the controller
  """
  @spec learn_mode([opt()]) :: any
  def learn_mode(opts \\ []) do
    case InclusionRunnerSupervisor.start_runner(opts) do
      {:ok, runner} ->
        InclusionRunner.learn_mode(runner)
    end
  end

  @doc """
  Stop learn mode on the controller
  """
  @spec learn_mode_stop :: any
  def learn_mode_stop() do
    InclusionRunner.learn_mode_stop(InclusionRunner)
  end

  @doc """
  Stop the inclusion runner
  """
  @spec stop :: :ok
  def stop() do
    InclusionRunner.stop(InclusionRunner)
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
