defprotocol Grizzly.ZWaveCommand do
  def to_binary(commnad)

  def from_binary(command, binary)
end
