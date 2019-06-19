defmodule Grizzly.Application do
  use Application
  require Logger

  def start(_type, _args) do
    _ = Logger.info("Starting Grizzly")

    children =
      [
        Grizzly.Notifications,
        {Grizzly.SeqNumber, Enum.random(0..255)},
        {DynamicSupervisor, name: Grizzly.Conn.Supervisor, strategy: :one_for_one},
        {Grizzly.UnsolicitedServer, unsolicited_server_config()},
        Grizzly.Controller.Supervisor,
        Grizzly.UnsolicitedServer.Socket.Supervisor,
        Grizzly.Inclusion,
        Grizzly.Network.State
      ]
      |> maybe_append_muontrap()

    opts = [strategy: :one_for_one, name: Grizzly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp unsolicited_server_config() do
    Grizzly.UnsolicitedServer.Config.new(
      ip_version: :inet6,
      ip_address: {0xFD00, 0xAAAA, 0, 0, 0, 0, 0, 0x0002}
    )
  end

  defp maybe_append_muontrap(children_list) do
    case Application.get_env(:grizzly, :run_grizzly, true) do
      true ->
        priv_dir = :code.priv_dir(:grizzly) |> to_string()

        [
          {MuonTrap.Daemon,
           [
             "zipgateway",
             ["-c", Path.join(priv_dir, "zipgateway.cfg")],
             [cd: priv_dir, log_output: :debug]
           ]}
        ] ++ children_list

      false ->
        children_list
    end
  end
end
