defprotocol ZipGateway.Packet.Encoder do
  @type t :: term

  @spec encode(t) :: binary
  def encode(value)
end
