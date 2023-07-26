defmodule Grizzly.ZWave.Commands.SoundSwitchTonesNumberReport do
  @moduledoc """
  This command is used to advertise the number of tones supported by the sending
  node.

  ## Params

  * `:supported_tones` - the number of supported tones
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SoundSwitch

  @type param :: {:supported_tones, 0..255}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sound_switch_tones_number_report,
      command_byte: 0x02,
      command_class: SoundSwitch,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    supported_tones = Command.param!(command, :supported_tones)
    <<supported_tones::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<supported_tones::8>>) do
    {:ok, [supported_tones: supported_tones]}
  end
end
