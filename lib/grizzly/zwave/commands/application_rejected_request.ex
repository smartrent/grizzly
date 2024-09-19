defmodule Grizzly.ZWave.Commands.ApplicationRejectedRequest do
  @moduledoc """
  This command is used to instruct a node that the command was rejected by the
  application in the receiving node.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ApplicationStatus

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :application_rejected_request,
      command_byte: 0x02,
      command_class: ApplicationStatus,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    # "status" must always be 0
    <<0x00>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
