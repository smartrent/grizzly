defmodule Grizzly.ZWave.Commands.TimeParametersGet do
  @moduledoc """
  This command is used to request date and time parameters.

  Params:- none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.TimeParameters

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :time_parameters_get,
      command_byte: 0x02,
      command_class: TimeParameters,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
