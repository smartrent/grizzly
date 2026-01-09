defmodule Grizzly.ZWave.Commands.CredentialGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CredentialGet

  test "encodes params correctly" do
    params = [
      user_id: 1,
      credential_type: :uwb,
      credential_slot: 2
    ]

    assert {:ok, command} = Commands.create(:credential_get, params)

    assert CredentialGet.encode_params(command) == <<
             1::16,
             0x06,
             2::16
           >>
  end

  test "decodes params correctly" do
    binary = <<
      1::16,
      0x06,
      2::16
    >>

    assert {:ok, params} = CredentialGet.decode_params(binary)
    assert params[:user_id] == 1
    assert params[:credential_type] == :uwb
    assert params[:credential_slot] == 2
  end
end
