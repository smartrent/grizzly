defmodule GrizzlyTest.Utils do
  @moduledoc false

  alias Grizzly.Options
  alias Grizzly.ZWave.DSK

  defmodule TestInclusionHandler do
    @moduledoc false

    @behaviour Grizzly.InclusionHandler

    require Logger

    def handle_report(report, _opts) do
      Logger.info("Inclusion Handler: #{inspect(report)}")

      :ok
    end

    def handle_timeout(_, _) do
      :ok
    end
  end

  @spec default_options_args() :: [Grizzly.Supervisor.arg()]
  def default_options_args() do
    [
      transport: GrizzlyTest.Transport.DTLS,
      lan_ip: {127, 0, 0, 1},
      pan_ip: {127, 0, 0, 1},
      zipgateway_port: 5000,
      unsolicited_destination: {{127, 0, 0, 1}, 5001},
      run_zipgateway: false,
      inclusion_handler: TestInclusionHandler,
      inclusion_adapter: GrizzlyTest.InclusionAdapter
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
