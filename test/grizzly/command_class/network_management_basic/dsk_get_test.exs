defmodule Grizzly.CommandClass.NetworkManagementBasic.DSKGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.NetworkManagementBasic
  alias Grizzly.CommandClass.NetworkManagementBasic.DSKGet

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %DSKGet{}} == DSKGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = DSKGet.init(seq_number: 10, add_mode: :learn)

      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x4D, 0x08, 10, 0x00>>

      assert {:ok, binary} == DSKGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = DSKGet.init(seq_number: 0x05)
      packet = Packet.new(seq_number: 0x05, types: [:ack_response])

      assert {:continue, ^command} = DSKGet.handle_response(command, packet)
    end

    test "handles nack response" do
      {:ok, command} = DSKGet.init(seq_number: 0x07, retries: 0)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == DSKGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = DSKGet.init(seq_number: 0x07)
      packet = Packet.new(seq_number: 0x07, types: [:nack_response])

      assert {:retry, %DSKGet{}} = DSKGet.handle_response(command, packet)
    end

    test "handles queued for wake up nodes" do
      {:ok, command} = DSKGet.init(seq_number: 0x01, add_mode: :add)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(5000)

      assert {:queued, ^command} = DSKGet.handle_response(command, packet)
    end

    test "handles nack waiting when delay is 1 or less" do
      {:ok, command} = DSKGet.init(seq_number: 0x01)

      packet =
        Packet.new(seq_number: 0x01, types: [:nack_response, :nack_waiting])
        |> Packet.put_expected_delay(1)

      assert {:continue, ^command} = DSKGet.handle_response(command, packet)
    end

    test "handles dsk report responses" do
      dsk = "38212-43450-54414-56613-50407-01928-44861-21469"

      report = %{
        command_class: NetworkManagementBasic,
        command: :dsk_report,
        report: %{
          dsk: dsk,
          add_mode: :add
        }
      }

      packet = Packet.new(body: report)
      {:ok, command} = DSKGet.init(add_mode: :add)

      assert {:done, {:ok, %{dsk: dsk, add_mode: :add}}} ==
               DSKGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = DSKGet.init([])
      assert {:continue, %DSKGet{}} = DSKGet.handle_response(command, %{command_class: :foo})
    end
  end
end
