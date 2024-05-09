defmodule Grizzly.ZWave.Security.S0NonceTable do
  @moduledoc """
  This module is used to generate and store S0 nonces in response to incoming
  Security Nonce Get commands.
  """

  use GenServer

  require Logger

  # The spec says the TTL can be in the range 3..20 seconds. We'll default to 20
  # seconds to maximize compatibility.
  @default_nonce_ttl :timer.seconds(20)
  @nonce_bytes 8

  @type nonce :: <<_::128>>
  @type nonce_id :: byte()

  @type random_fun :: (bytes :: pos_integer() -> <<_::_*8>>)
  @type option ::
          {:ttl, non_neg_integer()}
          | {:name, GenServer.name()}
          | {:random_fun, random_fun()}

  @typep nonce_entry :: {nonce_id(), node_id :: pos_integer(), nonce(), generated_at :: integer()}
  @typep nonce_table :: [nonce_entry()]

  @spec generate(GenServer.server(), node_id :: pos_integer()) :: {:ok, nonce()} | :error
  def generate(server \\ __MODULE__, node_id) do
    GenServer.call(server, {:generate, node_id})
  end

  @doc """
  Takes a nonce from the nonce table. If the nonce is not found, `nil` is returned.
  The nonce will be removed from the nonce table.
  """
  @spec take(GenServer.server(), node_id :: pos_integer(), nonce_id :: nonce_id()) ::
          nonce() | nil
  def take(server \\ __MODULE__, node_id, nonce_id) do
    GenServer.call(server, {:take, node_id, nonce_id})
  end

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    ttl = Keyword.get(opts, :ttl, @default_nonce_ttl)
    random_fun = Keyword.get(opts, :random_fun, &:crypto.strong_rand_bytes/1)
    state = %{nonce_table: [], ttl: ttl, random_fun: random_fun}
    {:ok, state}
  end

  @impl GenServer
  def handle_continue(:expire, state) do
    nonce_table =
      Enum.reduce(state.nonce_table, [], fn entry, acc ->
        if valid?(entry, state.ttl) do
          [entry | acc]
        else
          Logger.debug(
            "[Grizzly] Expiring nonce with id #{inspect(elem(entry, 0))} for node #{elem(entry, 1)}"
          )

          acc
        end
      end)

    {:noreply, %{state | nonce_table: nonce_table}}
  end

  @impl GenServer
  def handle_call({:generate, node_id}, _from, state) do
    case do_generate(state, node_id) do
      {:ok, {_, _, nonce, _} = nonce_entry} ->
        state = %{state | nonce_table: [nonce_entry | state.nonce_table]}
        {:reply, {:ok, nonce}, state, {:continue, :expire}}

      :error ->
        {:reply, :error, state, {:continue, :expire}}
    end
  end

  def handle_call({:take, node_id, nonce_id}, _from, state) do
    {new_nonce_table, entry} = do_take(state.nonce_table, nonce_id, node_id)

    ret = if(not is_nil(entry) && valid?(entry, state.ttl), do: elem(entry, 2), else: nil)

    {:reply, ret, %{state | nonce_table: new_nonce_table}, {:continue, :expire}}
  end

  @spec do_take(nonce_table(), binary(), non_neg_integer(), nonce_table()) ::
          {updated_nonce_table :: nonce_table(), nonce_entry() | nil}
  defp do_take(nonce_table, nonce_id, node_id, processed \\ [])

  defp do_take([{nonce_id, node_id, _, _} = entry | tail], nonce_id, node_id, processed) do
    {Enum.concat(processed, tail), entry}
  end

  defp do_take([], _, _, processed), do: {processed, nil}

  defp do_take([entry | tail], nonce_id, node_id, processed) do
    do_take(tail, nonce_id, node_id, [entry | processed])
  end

  defp do_generate(state, node_id, attempts \\ 0)

  # If after 10 rounds of attempts we still can't generate a nonce with a unique
  # first byte, then we're probably under a DoS attack. We should prevent that
  # at a higher layer, but if it happens here, we'll just give up and return an
  # error.
  defp do_generate(_state, _node_id, attempts) when attempts >= 10, do: :error

  defp do_generate(state, node_id, attempts) do
    nonce = state.random_fun.(@nonce_bytes)

    <<nonce_id::8, _::binary>> = nonce

    # The first byte of the nonce is the nonce ID, which must be unique among
    # all active nonces.
    if nonce_id_conflict?(state.nonce_table, nonce_id, node_id) do
      do_generate(state, node_id, attempts + 1)
    else
      {:ok, {nonce_id, node_id, nonce, now_ms()}}
    end
  end

  @spec nonce_id_conflict?(nonce_table(), nonce_id, node_id :: pos_integer()) :: boolean()
  defp nonce_id_conflict?(nonce_table, nonce_id, node_id) do
    Enum.any?(nonce_table, fn {a, b, _, _} -> nonce_id == a && node_id == b end)
  end

  @spec valid?(nonce_entry(), non_neg_integer()) :: boolean()
  defp valid?({_nonce_id, _node_id, _nonce, generated_at}, ttl) do
    now_ms() - generated_at < ttl
  end

  defp now_ms(), do: System.monotonic_time() |> System.convert_time_unit(:native, :millisecond)
end
