defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

  @spec handle_response(Transport.t(), Transport.Response.t()) :: :ok
  def handle_response(transport, response) do
    case Command.param!(response.command, :flag) do
      :ack_request ->
        seq_number = Command.param!(response.command, :seq_number)
        command = ZIPPacket.make_ack_response(seq_number)

        binary = ZWave.to_binary(command)

        :ok = Transport.send(transport, binary, to: {response.ip_address, response.port})

      _ ->
        :ok = Messages.broadcast(response.ip_address, response.command)
    end
  end
end
