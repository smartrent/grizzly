defmodule Grizzly.ZWave.Commands.HumidityControlModeSupportedReport do
  @moduledoc """
  HumidityControlModeSupportedReport

  ## Parameters

  * `:modes`
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.HumidityControlMode
  alias Grizzly.ZWave.DecodeError

  @type param :: {:modes, [HumidityControlMode.mode()]}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    command
    |> Command.param!(:modes)
    |> Enum.map(&HumidityControlMode.encode_mode/1)
    |> encode_bitmask()
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(binary) do
    modes =
      binary
      |> decode_bitmask()
      |> Enum.map(&HumidityControlMode.decode_mode/1)
      |> Enum.reject(&(&1 == :unknown))

    {:ok, [modes: modes]}
  end
end
