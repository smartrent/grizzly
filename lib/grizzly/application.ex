defmodule Grizzly.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    runtime_opts = Application.get_env(:grizzly, :runtime, [])

    children = [
      # Supervisor for the zipgateway binary
      Grizzly.ZIPGateway.Supervisor,

      # According to Z-Wave specification we need to have a global
      # sequence number counter that starts at a random number between
      # 0 and 0xFF (255)
      {Grizzly.SeqNumber, Enum.random(0..255)},
      #
      {Registry, [keys: :duplicate, name: Grizzly.Events.Registry]},
      {Registry, [keys: :unique, name: Grizzly.ConnectionRegistry]},

      # TODO: move unsolicited server stuff to own supervisor
      Grizzly.UnsolicitedServer.Messages,
      Grizzly.UnsolicitedServer,
      Grizzly.UnsolicitedServer.SocketSupervisor,
      ##########################

      # Supervisor for starting connections to Z-Wave nodes
      Grizzly.Connections.Supervisor,

      # Supervisor for starting and stopping Z-Wave inclusions
      Grizzly.Inclusions.InclusionRunnerSupervisor,

      # Supervisor for running commands
      Grizzly.Commands.CommandRunnerSupervisor,

      # The runtime process that allows for control over when
      # the zipgateway binary is ran and helps notify when
      # everything looks set up
      {Grizzly.Runtime, runtime_opts}
    ]

    opts = [strategy: :one_for_one, name: Grizzly.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
