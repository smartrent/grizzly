defmodule Grizzly.ZWave.Commands.UserCredentialAssociationSetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.UserCredentialAssociationSet

  test "encodes params correctly" do
    params = [
      credential_type: :password,
      credential_slot: 1,
      destination_user_id: 2
    ]

    {:ok, command} = UserCredentialAssociationSet.new(params)

    assert UserCredentialAssociationSet.encode_params(command) ==
             <<2, 1::16, 2::16>>
  end

  test "decodes params correctly" do
    binary = <<2, 1::16, 2::16>>

    assert {:ok, params} = UserCredentialAssociationSet.decode_params(binary)

    assert params[:credential_type] == :password
    assert params[:credential_slot] == 1
    assert params[:destination_user_id] == 2
  end
end
