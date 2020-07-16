defmodule Grizzly.ZWave.Commands.TimeReport do
  @moduledoc """
  This command is used to report the current time.

  Params:
    * `:rtc_failure?` - Many RTC chips have a stop bit indicating if the oscillator has been stopped. The RTC failure bit MUST
                        be set to 1 in order to indicate to the receiving node that the RTC has been stopped and that the
                        advertised time might be inaccurate. (optional - defaults to false)
    * `:hour`   - the hour (required)
    * `:minute` - the minute (required)
    * `:second` - the second of the setpoint (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Time

  @type param ::
          {:hour, 0..23} | {:minute, 0..59} | {:second, 0..59}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(_params) do
    command = %Command{
      name: :time_report,
      command_byte: 0x02,
      command_class: Time,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    rtc_failure? = Command.param(command, :rtc_failure?, false)
    hour = Command.param!(command, :hour)
    minute = Command.param!(command, :minute)
    second = Command.param!(command, :second)
    rtc_failure_bit = if rtc_failure?, do: 1, else: 0
    <<rtc_failure_bit::size(1), 0x00::size(2), hour::size(5), minute, second>>
  end

  @impl true
  def decode_params(<<rtc_failure_bit::size(1), 0x00::size(2), hour::size(5), minute, second>>) do
    rtc_failure? = rtc_failure_bit == 1
    {:ok, [rtc_failure?: rtc_failure?, hour: hour, minute: minute, second: second]}
  end
end
