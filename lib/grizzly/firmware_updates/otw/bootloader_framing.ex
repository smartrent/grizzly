defmodule Grizzly.FirmwareUpdates.OTW.BootloaderFraming do
  @moduledoc """
  A Circuits.UART.Framing implementation for handling framing of data
  exchanged with the Gecko bootloader during over-the-wire firmware updates.
  """

  @behaviour Circuits.UART.Framing

  # These are the control characters we'll receive from the Gecko bootloader
  defguardp is_xmodem_control_char(byte) when byte in [0x06, 0x15, 0x18, ?C]

  @impl Circuits.UART.Framing
  def init(_args) do
    {:ok, <<>>}
  end

  @impl Circuits.UART.Framing
  def add_framing(data, _rx_buffer) when is_binary(data) do
    {:ok, data, <<>>}
  end

  @impl Circuits.UART.Framing
  def frame_timeout(buffer) do
    {:ok, [buffer], <<>>}
  end

  @impl Circuits.UART.Framing
  def flush(:transmit, rx_buffer), do: rx_buffer
  def flush(:receive, _rx_buffer), do: <<>>
  def flush(:both, _rx_buffer), do: <<>>

  @impl Circuits.UART.Framing
  def remove_framing(data, rx_buffer) do
    process_data(rx_buffer <> data, [])
  end

  # If we get a single byte and it's a control character, emit it as a frame.
  defp process_data(<<ctrl>>, frames) when is_xmodem_control_char(ctrl) do
    {:ok, frames ++ [<<ctrl>>], <<>>}
  end

  # Whenever the input starts with a potential control character (ASCII ACK, NAK,
  # CAN, or 'C'), emit the control character as a single-byte frame.
  defp process_data(<<ctrl, rest::binary>>, frames) when is_xmodem_control_char(ctrl) do
    process_data(rest, frames ++ [<<ctrl>>])
  end

  defp process_data(data, frames) when byte_size(data) >= 1 do
    cond do
      # If the entire buffer is printable, put it into the buffer. The Gecko bootloader
      # sends a null character when it's ready for input.
      String.printable?(data) ->
        {:ok, frames, data}

      # If the entire buffer is printable after stripping out null bytes, split
      # on the null bytes and emit each printable segment as a frame.
      String.printable?(String.replace(data, <<0>>, "")) ->
        String.split(data, <<0>>, trim: true)
        |> Enum.reduce({:ok, frames, <<>>}, fn segment, {status, frames, buffer} ->
          if String.printable?(segment) do
            {status, frames ++ [segment], buffer}
          else
            {status, frames, buffer <> segment}
          end
        end)

      # Otherwise, try to detect a Z-Wave SAPI frame.
      true ->
        {:ok, frames ++ [data], <<>>}
    end
  end

  # Rx buffer is empty. Emit all accumulated frames.
  defp process_data(<<>>, frames) do
    {:ok, frames, <<>>}
  end

  # Anything else gets emitted as a frame.
  defp process_data(data, frames) do
    {:ok, frames ++ [data], <<>>}
  end
end
