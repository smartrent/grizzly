defmodule Grizzly.Commands.ZIPKeepAlive do
  @type type :: :ack_response | :ack_request

  defstruct type: nil

  def from_binary(<<0x23, 0x03, 0x40>>), do: {:ok, %__MODULE__{type: :ack_response}}

  def from_binary(<<0x23, 0x03, 0x80>>), do: {:ok, %__MODULE__{type: :ack_request}}

  def from_binary(binary), do: {:error, :invalid_binary}

  def encode_type(:ack_request), do: {:ok, 0x80}
  def encode_type(:ack_response), do: {:ok, 0x40}
  def encode_type(_), do: {:error, :invalidate_type}
end
