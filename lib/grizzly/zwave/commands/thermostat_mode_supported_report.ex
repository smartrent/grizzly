defmodule Grizzly.ZWave.Commands.ThermostatModeSupportedReport do
  @moduledoc """
  This command is used to report the thermostat's supported modes.

  Params:

    * `:modes` - A list of supported modes. See `t:Grizzly.ZWave.CommandClasses.ThermostatMode.mode/0`.

  """

  @behaviour Grizzly.ZWave.Command

  import Bitwise

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ThermostatMode

  @type param :: {:modes, [{ThermostatMode.mode(), boolean()}]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :thermostat_mode_supported_report,
      command_byte: 0x05,
      command_class: ThermostatMode,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    modes = Command.param!(command, :modes)

    encode_modes(modes)
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(bitmasks) when byte_size(bitmasks) < 4,
    do: decode_params(<<bitmasks::binary, 0x0::8>>)

  def decode_params(bitmasks) do
    modes =
      for {byte, byte_index} <- Enum.with_index(:binary.bin_to_list(bitmasks)),
          bit_index <- 0..7,
          {status, mode} = ThermostatMode.decode_mode(byte_index * 8 + bit_index),
          status == :ok,
          into: [] do
        {mode, (byte &&& 1 <<< bit_index) !== 0}
      end

    {:ok, [modes: modes]}
  end

  @spec encode_modes([{ThermostatMode.mode(), boolean()}]) :: binary()
  defp encode_modes([]), do: <<>>

  defp encode_modes(modes) do
    supported_modes =
      modes
      |> Enum.filter(fn {_mode, supported} -> supported end)
      |> Enum.map(fn {mode, _supported} -> ThermostatMode.encode_mode(mode) end)
      |> Enum.filter(&is_integer/1)

    byte_count = max(1, ceil(Enum.max(supported_modes) / 8))

    bitmasks = for _ <- 1..byte_count, into: [], do: 0

    supported_modes
    |> Enum.reduce(bitmasks, fn mode_value, acc ->
      byte_index = Integer.floor_div(mode_value, 8)
      bit_index = Integer.mod(mode_value, 8)

      List.replace_at(acc, byte_index, Enum.at(acc, byte_index, 0) ||| 1 <<< bit_index)
    end)
    |> :binary.list_to_bin()
  end
end
