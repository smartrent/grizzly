defmodule Grizzly.Conn.Response do
  @type t :: %__MODULE__{
          request_id: non_neg_integer | nil,
          body: term,
          types: [type]
        }

  @type type :: :ack_response

  defstruct request_id: nil, body: nil, types: nil
end
