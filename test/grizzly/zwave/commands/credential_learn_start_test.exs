defmodule Grizzly.ZWave.Commands.CredentialLearnStartTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.CredentialLearnStart

  test "encodes params correctly" do
    params = [
      user_id: 1,
      credential_type: :password,
      credential_slot: 1,
      operation_type: :modify,
      learn_timeout: 30
    ]

    {:ok, command} = CredentialLearnStart.new(params)

    assert CredentialLearnStart.encode_params(command) == <<1::16, 2, 1::16, 1, 30>>
  end

  test "decodes params correctly" do
    binary = <<1::16, 2, 1::16, 1, 30>>

    assert {:ok, params} = CredentialLearnStart.decode_params(binary)

    assert params[:user_id] == 1
    assert params[:credential_type] == :password
    assert params[:credential_slot] == 1
    assert params[:operation_type] == :modify
    assert params[:learn_timeout] == 30
  end
end
