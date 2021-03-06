defmodule GrizzlyTest.Utils do
  @moduledoc false

  alias Grizzly.Options
  alias Grizzly.ZWave.DSK

  @spec default_options_args() :: [Grizzly.Supervisor.arg()]
  def default_options_args() do
    [
      transport: GrizzlyTest.Transport.UDP,
      lan_ip: {0, 0, 0, 1},
      pan_ip: {0, 0, 0, 0},
      run_zipgateway: false
    ]
  end

  @spec default_options() :: Options.t()
  def default_options() do
    default_options_args()
    |> Options.new()
  end

  @spec mkdsk() :: DSK.t()
  def mkdsk() do
    dsk_string = "50285-18819-09924-30691-15973-33711-04005-03623"
    {:ok, dsk} = DSK.parse(dsk_string)

    dsk
  end
end
