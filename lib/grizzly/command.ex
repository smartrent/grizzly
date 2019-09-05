defmodule Grizzly.Command do
  @moduledoc """
  Command is a server managing the overall lifecycle of the execution of a command,
  from start to completion or timeout.

  When starting the execution of a command, the state of the network is checked to see if it is
  in one of the allowed states for executing this particular command. The allowed states are listed
  in the `pre_states` property of the command being started. If the property is absent, the default
  allowed states are [:idle]. If the network is not in an allowed state, {:error, :network_busy} is returned.

  If the started command has an `exec_state` property, the network state is set to its value for the duration
  of the execution of the command. If there is none, the network state is unchanged.

  If the started command has a `post_state` property, the network state is set to it after the command execution
  completes or times out. If there is none, the network state is set to :idle.

  If the started command has a `timeout` property, a timeout is set to its value. If the command does not complete
  before the timeout expires, the command's execution is stopped and a {:timeout, <command module>} message is sent to
  the process that started the execution of the command.
  """

  use GenServer

  alias Grizzly.{Packet, SeqNumber}
  alias Grizzly.Network.State, as: NetworkState
  alias Grizzly.Command.EncodeError
  require Logger

  @type t :: pid

  @type handle_instruction ::
          {:continue, state :: any}
          | {:done, response :: any}
          | {:retry, state :: any}
          | {:send_message, message :: any, state :: any}
          | {:queued, state :: any}

  @callback init(args :: term) :: :ok | {:ok, command :: any}

  @callback encode(command :: any) :: {:ok, binary} | {:error, EncodeError.t() | any()}

  @callback handle_response(command :: any, Packet.t()) :: handle_instruction

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            command_module: module(),
            command: any,
            timeout_ref: pid,
            starter: pid
          }

    defstruct command_module: nil,
              command: nil,
              timeout_ref: nil,
              starter: nil
  end

  @spec start(module, opts :: keyword) :: GenServer.on_start()
  def start(module, opts) do
    _ = Logger.debug("Starting command #{inspect(module)} with args #{inspect(opts)}")
    command_args = Keyword.put_new(opts, :seq_number, SeqNumber.get_and_inc())
    {:ok, command} = apply(module, :init, [command_args])

    if not NetworkState.in_allowed_state?(Map.get(command, :pre_states)) do
      _ =
        Logger.warn(
          "Command #{module} not starting in allowed network states #{
            inspect(Map.get(command, :pre_states))
          }"
        )

      {:error, :network_busy}
    else
      :ok = NetworkState.set(Map.get(command, :exec_state))

      GenServer.start(
        __MODULE__,
        command_module: module,
        command: command,
        starter: self()
      )
    end
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(command) do
    GenServer.call(command, :encode)
  end

  @spec handle_response(t, %Packet{}) ::
          {:finished, value :: any()}
          | :continue
          | :retry
          | :queued
          | {:send_message, message :: any()}
  def handle_response(command, packet) do
    GenServer.call(command, {:handle_response, packet}, 60_000 * 2)
  end

  @spec complete(t) :: :ok
  def complete(command) do
    GenServer.call(command, :complete)
  end

  @impl true
  def init(
        command_module: command_module,
        command: command,
        starter: starter
      ) do
    timeout_ref = setup_timeout(Map.get(command, :timeout))

    {
      :ok,
      %State{
        command_module: command_module,
        command: command,
        timeout_ref: timeout_ref,
        starter: starter
      }
    }
  end

  @impl true
  def terminate(:normal, _state) do
    :ok
  end

  def terminate(reason, %State{command: command}) do
    _ =
      Logger.warn(
        "Command #{inspect(command)} terminated with #{inspect(reason)}. Resetting network state to idle"
      )

    NetworkState.set(:idle)
    :ok
  end

  # Upon command completion, clear any timeout and
  # set the network state to what the command specifies (defaults to :idle).
  @impl true
  def handle_call(:complete, _from, %State{command: command, timeout_ref: timeout_ref} = state) do
    _ = clear_timeout(timeout_ref)

    post_state = Map.get(command, :post_state, :idle)
    NetworkState.set(post_state)

    {:stop, :normal, :ok, %State{state | timeout_ref: nil}}
  end

  def handle_call(
        :encode,
        _,
        %State{command_module: command_module, command: command} = state
      ) do
    case apply(command_module, :encode, [command]) do
      {:ok, binary} ->
        {:reply, {:ok, binary}, state}

      {:error, _} = error ->
        {:stop, :normal, error, state}
    end
  end

  def handle_call(
        {:handle_response, %Packet{} = packet},
        _from,
        %State{command_module: command_module, command: command} = state
      ) do
    case apply(command_module, :handle_response, [command, packet]) do
      {:done, value} ->
        {:reply, {:finished, value}, state}

      {:send_message, message, new_command} ->
        {:reply, {:send_message, message}, %{state | command: new_command}}

      {:continue, new_command} ->
        {:reply, :continue, %{state | command: new_command}}

      {:retry, new_command} ->
        {:reply, :retry, %{state | command: new_command}}

      {:queued, new_command} ->
        {:reply, :queued, %{state | command: new_command}}
    end
  end

  @impl true
  def handle_info(:timeout, %State{starter: starter, command_module: command_module} = state) do
    send(starter, {:timeout, command_module})
    {:stop, :normal, %State{state | timeout_ref: nil}}
  end

  defp setup_timeout(nil), do: nil

  defp setup_timeout(timeout) do
    Process.send_after(self(), :timeout, timeout)
  end

  defp clear_timeout(nil), do: :ok
  defp clear_timeout(timeout_ref), do: Process.cancel_timer(timeout_ref)
end
