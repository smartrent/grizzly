defmodule Grizzly.ZWave.Commands.HumidityControlModeSupportedReport do
  @moduledoc """
  HumidityControlModeSupportedReport

  ## Parameters

  * `:modes`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControl

  @type param :: {:modes, [HumidityControl.mode()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    command
    |> Command.param!(:modes)
    |> Enum.map(&HumidityControl.encode_mode/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, binary) do
    modes =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControl.decode_mode/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [modes: modes]}
  end
end
