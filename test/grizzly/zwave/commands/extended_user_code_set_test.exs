defmodule Grizzly.ZWave.Commands.ExtendedUserCodeSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.ExtendedUserCodeSet

  test "encodes params correctly" do
    params = [
      user_codes: [
        %{user_id_status: :occupied, user_id: 36, user_code: "873227"},
        %{user_id_status: :disabled, user_id: 37, user_code: "12345678"}
      ]
    ]

    binary =
      params
      |> ExtendedUserCodeSet.new()
      |> elem(1)
      |> ExtendedUserCodeSet.encode_params()

    expected_binary =
      <<2::8, 36::16, 1::8, 6::8, "873227"::binary, 37::16, 2::8, 8::8, "12345678"::binary>>

    assert binary == expected_binary
  end

  test "decodes params correctly" do
    input =
      <<2::8, 36::16, 1::8, 6::8, "873227"::binary, 37::16, 2::8, 8::8, "12345678"::binary>>

    {:ok, params} = ExtendedUserCodeSet.decode_params(input)

    assert [code1, code2] = params[:user_codes]

    assert code1[:user_id] == 36
    assert code1[:user_id_status] == :occupied
    assert code1[:user_code] == "873227"

    assert code2[:user_id] == 37
    assert code2[:user_id_status] == :disabled
    assert code2[:user_code] == "12345678"
  end
end
