defmodule Grizzly.Commands do
  @moduledoc false

  # module for providing away to setup and tie Z-Wave commands into the
  # Grizzly runtime for handling commands

  alias Grizzly.Commands.{CommandRunner, CommandRunnerSupervisor}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  @doc """
  Takes a Z-Wave command and returns a runtime process for that command

  This command process is supervised and will stop once the command has
  completed its life cycle or until the timeout has expired
  """
  @spec create_command(Command.t(), keyword()) :: {:ok, pid()}
  def create_command(zwave_command, opts \\ []) do
    CommandRunnerSupervisor.start_runner(zwave_command, opts)
  end

  @doc """
  For a running command try to handle the Z/IP Packet
  """
  @spec handle_zip_packet_for_command(pid(), ZIPPacket.t()) ::
          :continue
          | :retry
          | {:complete, any()}
          | {:error, :nack_response}
          | {:queued, non_neg_integer()}
  def handle_zip_packet_for_command(command, zip_packet) do
    CommandRunner.handle_zip_command(command, zip_packet)
  end

  @doc """
  Stop a command runtime
  """
  @spec stop(pid()) :: :ok
  def stop(runner) do
    CommandRunner.stop(runner)
  end
end
