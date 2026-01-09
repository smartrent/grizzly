defmodule Grizzly.ZWave.Commands.S2ResynchronizationEvent do
  @moduledoc """
  S2 Resynchronization Event

  This event is defined in zipgateway, but doesn't seem to be officially
  documented yet. From zipgateway:

  ```
  SOS_EVENT_REASON_UNANSWERED means that a Nonce Report with Singlecast-out-of-Sync
  (SOS) = 1 has been received at an unexpected time and no response was sent.

  A Nonce Report SOS is considered expected and no SOS_EVENT_REASON_UNANSWERED will be emitted in these case:
    1) libs2 is in Verify Delivery state and receives a Nonce Report SOS from the
       node being delivered to and will re-transmit the encrypted message
    2) libs2 has already re-transmitted and receives a second SOS from the node being transmitted to
       during Verify Delivery timeout. A \ref S2_send_done_event() with
       status=TRANSMIT_COMPLETE_NO_ACK will be emitted instead.
  ```

  Params:

    * `:node_id` - which node this message pertains to
    * `:reason` - 0 = SOS_EVENT_REASON_UNANSWERED in zipgateway
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.NodeId

  @impl Command
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    reason = Command.param!(command, :reason)

    NodeId.encode_extended(node_id, delimiter: <<reason>>)
  end

  @impl Command
  def decode_params(<<_node_id_8, reason, _node_id_16::binary>> = params) do
    node_id = NodeId.parse(params, delimiter_size: 1)

    {:ok, [node_id: node_id, reason: reason]}
  end
end
