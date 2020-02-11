defmodule Grizzly.Runtime do
  @moduledoc """

  Cofiguration params:

    * `:auto_start` - setup runtime when Grizzly application starts
    * `:on_ready` - a `{module, function, args}` to call after the runtime
      seems to be up and running correctly
    * `:run_zipgateway_bin` - if you run `zipgateway` outside of Grizzly you can
      set this to false

  Example:

  ```elixir
  config :grizzly,
    runtime: [
      auto_start: true,
      on_ready: {MyModule, :grizzly_ready, []},
      run_zipgateway_bin: true
    ]
  ```

  You're using Grizzly on a Nerves system, this config is probably what you
  want:

  ```elixir
  config :grizzly,
    runtime: [
      on_ready: {MyFirmwareProject.ZWave, :ready, []}
    ]
  ```

  The other defaults should work.
  """
  use GenServer

  alias Grizzly.{ZIPGateway, Connection}

  @type opt :: {:auto_start, boolean()} | {:on_ready, mfa()} | {:run_zipgateway_bin, boolean()}

  defmodule State do
    @moduledoc false
    # TODO use status?
    defstruct opts: [], on_ready: nil, status: nil
  end

  @spec start_link([opt]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    case Keyword.get(opts, :auto_start, true) do
      true ->
        {:ok, %State{opts: opts}, {:continue, next_continue(opts)}}

      false ->
        {:ok, %State{opts: opts}}
    end
  end

  @impl true
  def handle_continue(:run_zipgateway_bin, state) do
    # start the zipgateway binary
    :ok = ZIPGateway.run_zipgateway()

    # wait a little as it can take some time for zipgateway
    # to get complete setup
    :timer.sleep(500)

    {:noreply, state, {:continue, :try_connect}}
  end

  def handle_continue(:try_connect, state) do
    case Connection.open(1) do
      {:ok, _} ->
        :ok = maybe_run_on_ready(state.opts)
        {:noreply, state}

      {:error, :timeout} ->
        # give a little breathing space
        :timer.sleep(250)

        # try again
        {:noreply, state, {:continue, :try_connect}}
    end
  end

  defp maybe_run_on_ready(opts) do
    case Keyword.get(opts, :on_ready) do
      nil ->
        :ok

      {m, f, a} ->
        apply(m, f, a)
        :ok
    end
  end

  defp next_continue(opts) do
    if Keyword.get(opts, :run_zipgateway_bin, true) do
      :run_zipgateway_bin
    else
      :try_connect
    end
  end
end
