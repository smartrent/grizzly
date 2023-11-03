defmodule Grizzly.ZIPGateway.LogMonitor do
  @moduledoc """
  Monitors the Z/IP Gateway logs to extract and process certain data.
  """

  use GenServer

  require Logger

  @type serial_api_status :: :ok | :initializing | :unknown | :unresponsive

  @type network_key_type ::
          :s0
          | :s2_unauthenticated
          | :s2_authenticated
          | :s2_access_control
          | :s2_authenticated_long_range
          | :s2_access_control_long_range

  @doc """
  Returns the estimated status of the Z-Wave module based on Z/IP Gateway's
  log output.
  """
  @spec serial_api_status(GenServer.name()) :: serial_api_status()
  def serial_api_status(name \\ __MODULE__) do
    GenServer.call(name, :serial_api_status)
  end

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
  def init(opts) do
    {:ok,
     %{
       home_id: nil,
       network_keys: [],
       next_key_type: nil,
       sapi_retransmissions: 0,
       sapi_status: :unknown,
       status_reporter: opts[:status_reporter]
     }}
  end

  @impl GenServer
  def handle_call(:serial_api_status, _from, %{sapi_status: sapi_status} = state) do
    {:reply, sapi_status, state}
  end

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

  def handle_info({:message, "Serial Process init" <> _}, state) do
    {:noreply, set_sapi_status(state, :initializing)}
  end

  def handle_info({:message, "Bridge init done" <> _}, state) do
    {:noreply, set_sapi_status(state, :ok)}
  end

  def handle_info({:message, message}, state) do
    cond do
      not String.contains?(message, " SerialAPI: Retransmission") ->
        {:noreply, state}

      state.sapi_retransmissions + 1 > 4 ->
        {:noreply, set_sapi_status(state, :unresponsive)}

      true ->
        {:noreply, %{state | sapi_retransmissions: state.sapi_retransmissions + 1}}
    end
  end

  defp set_sapi_status(state, new_status) when new_status in [:ok, :initializing] do
    maybe_notify_status_reporter(state, new_status)
    %{state | sapi_status: new_status, sapi_retransmissions: 0}
  end

  defp set_sapi_status(state, new_status) do
    maybe_notify_status_reporter(state, new_status)
    %{state | sapi_status: new_status}
  end

  defp maybe_notify_status_reporter(%{sapi_status: status}, status), do: :ok

  defp maybe_notify_status_reporter(state, new_status) do
    cond do
      is_function(state.status_reporter, 1) ->
        state.status_reporter.(new_status)

      is_atom(state.status_reporter) and
          function_exported?(state.status_reporter, :serial_api_status, 1) ->
        state.status_reporter.serial_api_status(new_status)

      true ->
        :ok
    end

    :ok
  end
end
