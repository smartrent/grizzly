defmodule Grizzly.Requests do
  @moduledoc false

  # module for providing away to setup and tie Z-Wave commands into the
  # Grizzly runtime for handling commands

  alias Grizzly.Report
  alias Grizzly.Requests.{RequestRunner, RequestRunnerSupervisor}
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @doc """
  Takes a Z-Wave command and returns a runtime process for that command

  This command process is supervised and will stop once the command has
  completed its life cycle or until the timeout has expired
  """
  @spec start_request_runner(Command.t(), ZWave.node_id(), keyword()) ::
          DynamicSupervisor.on_start_child()
  def start_request_runner(zwave_command, node_id, opts \\ []) do
    RequestRunnerSupervisor.start_runner(zwave_command, node_id, opts)
  end

  @doc """
  For a running command try to handle the Z/IP Packet
  """
  @spec handle_zip_packet_for_command(pid(), Command.t()) ::
          :continue
          | :retry
          | {:error, :nack_response}
          | Report.t()
  def handle_zip_packet_for_command(command, zip_packet) do
    RequestRunner.handle_zip_command(command, zip_packet)
  end

  @doc """
  Stop a command runtime
  """
  @spec stop(pid()) :: :ok
  def stop(runner) do
    RequestRunner.stop(runner)
  end
end
