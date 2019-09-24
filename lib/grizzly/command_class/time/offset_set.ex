defmodule Grizzly.CommandClass.Time.OffsetSet do
  @moduledoc """
  Command module for working with TIME OFFSET_SET command.

  command options:

    * `:sign_tzo` - This field is used to indicate the sign (plus or minus)
       to apply to the Hour TZO and Minute TZO field
    * `:hour_tzo` - This field is used to indicate the number of hours that
       the originating time zone deviates from UTC
    * `:minute_tzo` - This field is used to indicate the number of minutes
       that the originating time zone deviates UTC
    * `:sign_offset_dst` - This field is used to indicate the sign (plus or minus)
       for the Minute Offset DST field to apply to the current time while in the
       Daylight Saving Time
    * `:minute_offset_dst` - This field MUST indicate the number of minutes by which
       the current time is to be adjusted when Daylight Saving Time starts
    * `:month_start_dst` - This field MUST indicate the month of the year when Daylight
       Saving Time starts
    * `:day_end_dst` - This field MUST indicate the day of the month when Daylight Saving
       Time starts
    * `:hour_start_dst` - This field MUST indicate the hour of the day when Daylight
       Saving Time starts
    * `:month_end_dst` - This field MUST indicate the month of the year when Daylight
       Saving Time ends
    * `:day_end_dst` - This field MUST indicate the day of the month when Daylight Saving
       Time ends
    * `:seq_number` - The sequence number for the Z/IP Packet
    * `:retries` - The number times to retry to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.Command.{EncodeError, Encoding}
  alias Grizzly.CommandClass.Time

  @type t :: %__MODULE__{
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer(),
          value: Time.offset()
        }

  @type opt ::
          {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}
          | {:value, Time.offset()}

  defstruct seq_number: nil, retries: 2, value: nil

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary} | {:error, EncodeError.t()}
  def encode(
        %__MODULE__{
          value: %{
            sign_tzo: sign_tzo,
            # deviation from UTC
            hour_tzo: hour_tzo,
            minute_tzo: minute_tzo,
            sign_offset_dst: sign_offset_dst,
            minute_offset_dst: minute_offset_dst,
            # start of DST
            month_start_dst: month_start_dst,
            day_start_dst: day_start_dst,
            # end of DST
            hour_start_dst: hour_start_dst,
            month_end_dst: month_end_dst,
            day_end_dst: day_end_dst,
            hour_end_dst: hour_end_dst
          },
          seq_number: seq_number
        } = command
      ) do
    with {:ok, _encoded} <-
           Encoding.encode_and_validate_args(
             command,
             %{
               sign_tzo: :bit,
               hour_tzo: {:range, 0, 14},
               minute_tzo: {:range, 0, 59},
               sign_offset_dst: :bit,
               minute_offset_dst: {:range, 0, 59},
               month_start_dst: {:range, 1, 12},
               day_start_dst: {:range, 1, 31},
               hour_start_dst: {:range, 0, 59},
               month_end_dst: {:range, 1, 12},
               day_end_dst: {:range, 1, 31},
               hour_end_dst: {:range, 0, 59}
             },
             [:value]
           ) do
      binary =
        Packet.header(seq_number) <>
          <<
            0x8A,
            0x05,
            sign_tzo::size(1),
            hour_tzo::size(7),
            minute_tzo,
            sign_offset_dst::size(1),
            minute_offset_dst::size(7),
            month_start_dst,
            day_start_dst,
            hour_start_dst,
            month_end_dst,
            day_end_dst,
            hour_end_dst
          >>

      {:ok, binary}
    end
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t}
          | {:done, {:error, :nack_response}}
          | {:done, Time.offset()}
          | {:retry, t}
  def handle_response(
        %__MODULE__{seq_number: seq_number} = _command,
        %Packet{
          seq_number: seq_number,
          types: [:ack_response]
        }
      ) do
    {:done, :ok}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: 0},
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(
        %__MODULE__{seq_number: seq_number, retries: n} = command,
        %Packet{
          seq_number: seq_number,
          types: [:nack_response]
        }
      ) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(
        _,
        %Packet{
          body: %{
            command_class: :time,
            command: :time_offset_report,
            value: value
          }
        }
      ) do
    {:done, {:ok, value}}
  end

  def handle_response(command, _), do: {:continue, command}
end
