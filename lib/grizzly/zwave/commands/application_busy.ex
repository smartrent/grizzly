defmodule Grizzly.ZWave.Commands.ApplicationBusy do
  @moduledoc """
  The Application Busy Command used to instruct a node that the node that it is
  trying to communicate with is busy and is unable to service the request right
  now.

  Params:

    * `:status` - The status field can have the following values:
      :try_again_later, :try_again_after_wait, :request_queued
      (required)
    * `:wait_time` - The wait time field indicates the number of seconds a node
      should wait before retrying the request (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ApplicationStatus

  # give me some type specs for your params
  @type param :: {:status, ApplicationStatus.status()} | {:wait_time, :byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :application_busy,
      command_byte: 0x01,
      command_class: ApplicationStatus,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    status_byte = Command.param!(command, :status) |> ApplicationStatus.status_to_byte()
    wait_time = Command.param!(command, :wait_time)
    <<status_byte, wait_time>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<status_byte, wait_time>>) do
    with {:ok, status} <- ApplicationStatus.status_from_byte(status_byte) do
      {:ok, [status: status, wait_time: wait_time]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :application_busy}}
    end
  end
end
