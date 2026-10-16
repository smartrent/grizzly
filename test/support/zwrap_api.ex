defmodule GrizzlyTest.ZwrapAPI do
  @moduledoc false
  use Agent

  def start_link(opts) do
    owner = Keyword.fetch!(opts, :owner)
    send(owner, {:zwrap_started, opts})
    Agent.start_link(fn -> %{owner: owner, subscriber: nil, result: :ok} end)
  end

  def subscribe(controller) do
    subscriber = self()
    Agent.update(controller, &%{&1 | subscriber: subscriber})
  end

  def emit(controller, event, fields) do
    subscriber = Agent.get(controller, & &1.subscriber)
    send(subscriber, {:zwrap, event, fields})
  end

  def result(controller, result), do: Agent.update(controller, &%{&1 | result: result})

  def get_network_keys(controller),
    do:
      Agent.get(controller, fn state ->
        {:ok,
         Map.put_new(Map.get(state, :keys, %{assigned_key_mask: 0}), :home_id, <<1, 2, 3, 4>>)}
      end)

  def keys(controller, keys), do: Agent.update(controller, &Map.put(&1, :keys, keys))

  def maintenance_acquire(_controller), do: {:error, :busy}
  def control(_controller, :idle, []), do: {:ok, <<1>>}

  def control(_controller, :capabilities, []),
    do: {:ok, <<2, 1::16, 160::16, 1, 2, 3, 4, 0x7FF9::32>>}

  def control(controller, operation, opts) do
    %{owner: owner, result: result} = Agent.get(controller, & &1)
    send(owner, {:native_call, :control, [operation, opts]})
    if result == :ok, do: {:ok, <<>>}, else: result
  end

  for {name, arity} <- [
        send_data_appl: 4,
        start_secure_inclusion: 1,
        start_unsecure_inclusion: 1,
        abort_inclusion: 1,
        start_exclusion: 1,
        abort_exclusion: 1,
        grant_inclusion_keys: 3,
        accept_authenticated_dsk: 2,
        accept_unauthenticated_dsk: 1,
        set_default: 1,
        remove_failed_node: 2,
        add_provision: 3,
        delete_provision: 2,
        get_provision: 2,
        iter_get_provision: 3
      ] do
    args = Macro.generate_arguments(arity - 1, __MODULE__)

    def unquote(name)(controller, unquote_splicing(args)) do
      %{owner: owner, result: result} = Agent.get(controller, & &1)
      send(owner, {:native_call, unquote(name), [unquote_splicing(args)]})
      result
    end
  end
end
