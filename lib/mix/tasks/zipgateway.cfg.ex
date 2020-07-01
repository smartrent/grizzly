defmodule Mix.Tasks.Zipgateway.Cfg do
  @moduledoc """
  Prints the generated zipgateway config to the console

    mix zipgateway.cfg
  """

  use Mix.Task
  alias Grizzly.ZIPGateway.Config

  @shortdoc "Print the zipgateway configuration to the console"

  def run(_args) do
    config = Application.get_env(:grizzly, :zipgateway_cfg, %{})

    Config.new(config)
    |> Config.to_string()
    |> IO.puts()
  end
end
