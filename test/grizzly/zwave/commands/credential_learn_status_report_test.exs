defmodule Grizzly.ZWave.Commands.CredentialLearnStatusReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.CredentialLearnStatusReport

  test "encodes params correctly" do
    params = [
      status: :started,
      user_id: 1,
      credential_type: :password,
      credential_slot: 1,
      steps_remaining: 5
    ]

    {:ok, command} = Commands.create(:credential_learn_status_report, params)

    assert CredentialLearnStatusReport.encode_params(command) ==
             <<0, 1::16, 2, 1::16, 5>>
  end

  test "decodes params correctly" do
    binary = <<0, 1::16, 2, 1::16, 5>>

    assert {:ok, params} = CredentialLearnStatusReport.decode_params(binary)

    assert params[:status] == :started
    assert params[:user_id] == 1
    assert params[:credential_type] == :password
    assert params[:credential_slot] == 1
    assert params[:steps_remaining] == 5
  end
end
