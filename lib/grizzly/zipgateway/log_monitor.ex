defmodule Grizzly.ZIPGateway.LogMonitor do
  @moduledoc """
  Monitors the Z/IP Gateway logs to extract and process certain data.
  """

  use GenServer

  require Logger

  @type network_key_type ::
          :s0
          | :s2_unauthenticated
          | :s2_authenticated
          | :s2_access_control
          | :s2_authenticated_long_range
          | :s2_access_control_long_range

  @doc """
  Returns the network home id as extracted from the Z/IP Gateway logs.
  """
  @spec home_id(GenServer.name()) :: binary() | nil
  def home_id(name \\ __MODULE__) do
    GenServer.call(name, :home_id)
  end

  @doc """
  Returns a keyword list of the network keys extracted from the Z/IP Gateway logs.
  """
  @spec network_keys(GenServer.name()) :: [{network_key_type(), binary()}]
  def network_keys(name \\ __MODULE__) do
    GenServer.call(name, :network_keys)
  end

  @doc """
  Returns a string containing a filename and network keys formatted for use with the
  Zniffer application (available through Simplicity Studio on Windows).
  """
  @spec zniffer_network_keys(GenServer.name()) :: binary() | nil
  def zniffer_network_keys(name \\ __MODULE__) do
    home_id = home_id(name)
    network_keys = network_keys(name)

    cond do
      is_nil(home_id) ->
        nil

      length(network_keys) != 6 ->
        nil

      true ->
        """
        #{home_id}.txt:

        9F;#{network_keys[:s2_access_control]};1
        9F;#{network_keys[:s2_access_control_long_range]};1
        9F;#{network_keys[:s2_authenticated]};1
        9F;#{network_keys[:s2_authenticated_long_range]};1
        9F;#{network_keys[:s2_unauthenticated]};1
        98;#{network_keys[:s0]};1
        """
    end
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %{home_id: nil, network_keys: [], next_key_type: nil}}
  end

  @impl GenServer
  def handle_call(:home_id, _from, %{home_id: home_id} = state) do
    {:reply, home_id, state}
  end

  def handle_call(:network_keys, _from, %{network_keys: network_keys} = state) do
    {:reply, network_keys, state}
  end

  @impl GenServer
  # We have the next key type in state, so extract the network key and save it
  def handle_info({:message, network_key}, %{next_key_type: key_type} = state)
      when not is_nil(key_type) do
    network_key = network_key |> String.trim() |> String.upcase()

    if Regex.match?(~r/^[0-9A-F]{32}$/, network_key) do
      Logger.debug("[Grizzly] Extracted network key type=#{key_type} key=#{network_key}")
      updated_network_keys = Keyword.put(state.network_keys, key_type, network_key)
      {:noreply, %{state | network_keys: updated_network_keys, next_key_type: nil}}
    else
      Logger.error(
        "[Grizzly] #{inspect(key_type)} network key appears to be invalid: #{network_key}"
      )

      {:noreply, state}
    end
  end

  # The actual network key is printed on the next line, so save where we're at in state
  # for when we receive the next message.
  def handle_info({:message, "Key class 0x" <> _ = message}, state) do
    next_key_type =
      case Regex.named_captures(~r/Key class 0x\d+: (?<key_class>.+$)/, message) do
        %{"key_class" => "KEY_CLASS_S0"} ->
          :s0

        %{"key_class" => "KEY_CLASS_S2_UNAUTHENTICATED"} ->
          :s2_unauthenticated

        %{"key_class" => "KEY_CLASS_S2_AUTHENTICATED"} ->
          :s2_authenticated

        %{"key_class" => "KEY_CLASS_S2_ACCESS"} ->
          :s2_access_control

        %{"key_class" => "KEY_CLASS_S2_AUTHENTICATED_LR"} ->
          :s2_authenticated_long_range

        %{"key_class" => "KEY_CLASS_S2_ACCESS_LR"} ->
          :s2_access_control_long_range

        %{"key_class" => key_class} ->
          Logger.error("[Grizzly] Unknown network key class: #{key_class}")

          nil

        nil ->
          Logger.error(
            "[Grizzly] Unexpected Z/IP Gateway message while extracting network keys: #{message}"
          )

          nil
      end

    {:noreply, %{state | next_key_type: next_key_type}}
  end

  # Extract the Home ID from the ZIP_Router_Reset message
  def handle_info({:message, "ZIP_Router_Reset:" <> message}, state) do
    home_id =
      case Regex.named_captures(~r/Home ID = 0x(?<home_id>[0-9a-fA-F]{8})/, message) do
        %{"home_id" => home_id} ->
          Logger.debug("[Grizzly] Extracted Home ID from ZIP_Router_Reset message: #{home_id}")
          String.upcase(home_id)

        nil ->
          Logger.error(
            "[Grizzly] Error extracting Home ID from ZIP_Router_Reset message: #{message}"
          )

          nil
      end

    {:noreply, %{state | home_id: home_id}}
  end

  def handle_info({:message, _}, state) do
    {:noreply, state}
  end
end
