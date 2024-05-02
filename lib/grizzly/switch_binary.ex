defmodule Grizzly.SwitchBinary do
  @moduledoc """
  Commands for working with devices that support the Switch Binary command class
  """

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.SwitchBinaryReport

  @typedoc """
  Optional parameters used when setting the switch state

  - `:duration` - the duration that the transition from current state to target
    state should take (version 2).
  """
  @type set_opt() :: {:duration, non_neg_integer()}

  @typedoc """
  The value the switch's state can be set to
  """
  @type set_value() :: :on | :off

  @typedoc """
  The report received after requesting the state fo the switch using the
  `get/1` function.
  """
  @type report() :: %{
          target_value: SwitchBinaryReport.value(),
          current_value: SwitchBinaryReport.value() | nil,
          duration: byte() | nil,
          version: 1 | 2
        }

  @doc """
  Request the current state of the switch

  This command will return a `report()` in response.
  """
  @spec get(ZWave.node_id(), [Grizzly.command_opt()]) ::
          {:ok, report()}
          | {:queued, reference(), non_neg_integer()}
          | {:error, :timeout | :including | :updating_firmware | :nack_response | any()}
  def get(node_id, command_opts \\ []) do
    case Grizzly.send_command(node_id, :switch_binary_get, [], command_opts) do
      {:ok, %{type: :command} = report} ->
        target_value = Command.param!(report.command, :target_value)
        duration = Command.param(report.command, :duration)
        current_value = Command.param(report.command, :current_value)
        version = if duration, do: 2, else: 1

        report = %{
          current_value: current_value,
          duration: duration,
          target_value: target_value,
          version: version
        }

        {:ok, report}

      {:ok, %{type: :queued_delay} = report} ->
        {:queued, report.command_ref, report.queued_delay}

      {:ok, %{type: :timeout}} ->
        {:error, :timeout}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Set the target value of the binary switch

  Devices that support version 2 of the switch binary command class and
  optionally be passed a duration that specifies the duration of the
  transition from the current value to the target value.
  """
  @spec set(ZWave.node_id(), set_value(), [set_opt() | Grizzly.command_opt()]) ::
          :ok
          | {:queued, reference(), non_neg_integer()}
          | {:error, :timeout | :including | :updating_firmware | :nack_response | any()}
  def set(node_id, target_value, opts \\ []) do
    duration = Keyword.get(opts, :duration)
    send_opts = Keyword.drop(opts, [:duration])

    case Grizzly.send_command(
           node_id,
           :switch_binary_set,
           [target_value: target_value, duration: duration],
           send_opts
         ) do
      {:ok, %{type: :ack_response}} ->
        :ok

      {:ok, %{type: :queued_delay} = report} ->
        {:queued, report.command_ref, report.queued_delay}

      {:ok, %{type: :timeout}} ->
        {:error, :timeout}

      {:error, _reason} = error ->
        error
    end
  end
end
