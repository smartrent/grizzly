defmodule Grizzly.Test.TestProto do
  defmodule EchoRequest do
    defstruct seq_number: nil, echo_value: nil
  end

  def echo_request(echo_value, seq_number) do
    %EchoRequest{seq_number: seq_number, echo_value: echo_value}
  end

  def echo_response(echo_value, seq_number) do
    <<0x00, 0x00, 0x00, 0x00>> <> <<0x02, seq_number, echo_value>>
  end
end
