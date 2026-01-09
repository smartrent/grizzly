defmodule Grizzly.ZWave.Commands.S2MessageEncapsulationTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.S2MessageEncapsulation

  test "encodes params correctly" do
    {:ok, cmd} =
      Commands.create(
        :s2_message_encapsulation,
        seq_number: 0xAB,
        extensions: [
          span: <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>,
          mpan: [
            group_id: 20,
            mpan_state: <<17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>
          ],
          mgrp: 20,
          mos: true
        ],
        encrypted_extensions?: true,
        encrypted_payload: <<0xDE, 0xAD, 0xBE, 0xEF>>
      )

    binary = S2MessageEncapsulation.encode_params(cmd)

    assert binary ==
             <<0xAB, 0b00000011, 18, 0b11000001, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
               15, 16, 3, 0b11000011, 20, 2, 0b000000100, 0xDE, 0xAD, 0xBE, 0xEF>>

    {:ok, cmd} =
      Commands.create(
        :s2_message_encapsulation,
        seq_number: 0xEE,
        extensions: [mos: false],
        encrypted_payload: <<0xDE, 0xAD, 0xBE, 0xEF>>
      )

    binary = S2MessageEncapsulation.encode_params(cmd)

    assert binary == <<0xEE, 0, 0xDE, 0xAD, 0xBE, 0xEF>>
  end

  test "decodes params correctly" do
    {:ok, params} =
      S2MessageEncapsulation.decode_params(
        <<0xAB, 0b00000011, 18, 0b11000001, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
          3, 0b11000011, 20, 2, 0b000000100, 0xDE, 0xAD, 0xBE, 0xEF>>
      )

    assert params[:seq_number] == 0xAB
    assert params[:extensions][:span] == <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>
    assert params[:extensions][:mgrp] == 20
    assert params[:extensions][:mos] == true
    assert params[:encrypted_extensions?] == true
    assert params[:encrypted_payload] == <<0xDE, 0xAD, 0xBE, 0xEF>>

    {:ok, params} =
      S2MessageEncapsulation.decode_params(<<0xEE, 0, 0xDE, 0xAD, 0xBE, 0xEF>>)

    assert params[:seq_number] == 0xEE
    assert params[:extensions] == []
    assert params[:encrypted_extensions?] == false
    assert params[:encrypted_payload] == <<0xDE, 0xAD, 0xBE, 0xEF>>
  end
end
