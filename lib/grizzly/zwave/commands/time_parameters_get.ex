defmodule Grizzly.ZWave.Commands.TimeParametersGet do
  @moduledoc """
  This command is used to request date and time parameters.

  Params:- none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.TimeParameters

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :time_parameters_get,
      command_byte: 0x02,
      command_class: TimeParameters,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
