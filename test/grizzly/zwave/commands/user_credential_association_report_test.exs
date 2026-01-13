defmodule Grizzly.ZWave.Commands.UserCredentialAssociationReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.UserCredentialAssociationReport

  test "encodes params correctly" do
    params = [
      credential_type: :password,
      credential_slot: 1,
      destination_user_id: 2,
      status: :destination_user_id_nonexistent
    ]

    {:ok, command} = Commands.create(:user_credential_association_report, params)

    assert UserCredentialAssociationReport.encode_params(nil, command) ==
             <<2, 1::16, 2::16, 5>>
  end

  test "decodes params correctly" do
    binary = <<2, 1::16, 2::16, 5>>

    assert {:ok, params} = UserCredentialAssociationReport.decode_params(nil, binary)

    assert params[:credential_type] == :password
    assert params[:credential_slot] == 1
    assert params[:destination_user_id] == 2
    assert params[:status] == :destination_user_id_nonexistent
  end
end
