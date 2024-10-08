defmodule Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetReport do
  @moduledoc """
  This command is used to advertise the time zone offset and daylight savings parameters.

  Params:

    * `:sign_tzo` - Plus (0) or minus (1) sign to indicate a positive or negative offset from UTC.

    * `:hour_tzo` - Specify the number of hours that the originating time zone deviates from UTC.

    * `:minute_tzo` - Specify the number of minutes that the originating time zone deviates UTC.

    * `:sign_offset_dst` - Plus (0) or minus (1) sign to indicate a positive or negative offset from UTC.

    * `:minute_offset_dst` - This field MUST specify the number of minutes the time is to be adjusted when daylight savings mode is enabled.

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.ScheduleEntryLock

  @type param ::
          {:sign_tzo, :plus | :minus}
          | {:hour_tzo, integer()}
          | {:minute_tzo, integer()}
          | {:sign_offset_tzo, :plus | :minus}
          | {:minute_offset_dst, integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :schedule_entry_lock_time_offset_report,
      command_byte: 0x0C,
      command_class: ScheduleEntryLock,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    sign_tzo = Command.param!(command, :sign_tzo)
    hour_tzo = Command.param!(command, :hour_tzo)
    minute_tzo = Command.param!(command, :minute_tzo)
    sign_offset_dst = Command.param!(command, :sign_offset_dst)
    minute_offset_dst = Command.param!(command, :minute_offset_dst)

    sign_bit_tzo = sign_to_bit(sign_tzo)
    sign_bit_dst = sign_to_bit(sign_offset_dst)

    <<sign_bit_tzo::1, hour_tzo::7, minute_tzo, sign_bit_dst::1, minute_offset_dst::7>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<sign_bit_tzo::1, hour_tzo::7, minute_tzo, sign_bit_dst::1, minute_offset_dst::7>>
      ) do
    {:ok,
     [
       sign_tzo: bit_to_sign(sign_bit_tzo),
       hour_tzo: hour_tzo,
       minute_tzo: minute_tzo,
       sign_offset_dst: bit_to_sign(sign_bit_dst),
       minute_offset_dst: minute_offset_dst
     ]}
  end

  defp sign_to_bit(:plus), do: 0
  defp sign_to_bit(:minus), do: 1

  defp bit_to_sign(0), do: :plus
  defp bit_to_sign(1), do: :minus
end
