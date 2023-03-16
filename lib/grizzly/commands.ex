defmodule Grizzly.Commands do
  @moduledoc false

  # module for providing away to setup and tie Z-Wave commands into the
  # Grizzly runtime for handling commands

  alias Grizzly.Commands.{CommandRunner, CommandRunnerSupervisor}
  alias Grizzly.Report
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @doc """
  Takes a Z-Wave command and returns a runtime process for that command

  This command process is supervised and will stop once the command has
  completed its life cycle or until the timeout has expired
  """
  @spec create_command(Command.t(), ZWave.node_id(), keyword()) ::
          DynamicSupervisor.on_start_child()
  def create_command(zwave_command, node_id, opts \\ []) do
    CommandRunnerSupervisor.start_runner(zwave_command, node_id, opts)
  end

  @doc """
  For a running command try to handle the Z/IP Packet
  """
  @spec handle_zwave_command_for_command(pid(), Command.t()) ::
          :continue
          | :retry
          | {:error, :nack_response}
          | Report.t()
  def handle_zwave_command_for_command(command, zwave_command) do
    CommandRunner.handle_zwave_command(command, zwave_command)
  end

  @doc """
  Stop a command runtime
  """
  @spec stop(pid()) :: :ok
  def stop(runner) do
    CommandRunner.stop(runner)
  end
end
