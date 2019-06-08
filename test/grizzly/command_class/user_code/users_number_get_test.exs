defmodule Grizzly.CommandClass.UserCode.UsersNumberGet.Test do
  use ExUnit.Case, async: true

  alias Grizzly.Packet
  alias Grizzly.CommandClass.UserCode.UsersNumberGet

  describe "implements Grizzly.Command correctly" do
    test "initializes to command" do
      assert {:ok, %UsersNumberGet{}} == UsersNumberGet.init([])
    end

    test "encodes correctly" do
      {:ok, command} = UsersNumberGet.init(seq_number: 10)
      binary = <<35, 2, 128, 208, 10, 0, 0, 3, 2, 0, 0x63, 0x04>>

      assert {:ok, binary} == UsersNumberGet.encode(command)
    end

    test "handles ack responses" do
      {:ok, command} = UsersNumberGet.init(seq_number: 0x03)
      packet = Packet.new(seq_number: 0x03, types: [:ack_response])

      assert {:continue, ^command} = UsersNumberGet.handle_response(command, packet)
    end

    test "handles nack respones" do
      {:ok, command} = UsersNumberGet.init(seq_number: 0x03, retries: 0)
      packet = Packet.new(seq_number: 0x03, types: [:nack_response])

      assert {:done, {:error, :nack_response}} == UsersNumberGet.handle_response(command, packet)
    end

    test "handles retries" do
      {:ok, command} = UsersNumberGet.init(seq_number: 0x03)
      packet = Packet.new(seq_number: 0x03, types: [:nack_response])

      assert {:retry, _command} = UsersNumberGet.handle_response(command, packet)
    end

    test "handles users number report response" do
      report = %{command_class: :user_code, command: :users_number_report, value: 100}
      {:ok, command} = UsersNumberGet.init(seq_number: 0x04)
      packet = Packet.new(body: report)

      assert {:done, {:ok, 100}} == UsersNumberGet.handle_response(command, packet)
    end

    test "handles responses" do
      {:ok, command} = UsersNumberGet.init([])

      assert {:continue, ^command} =
               UsersNumberGet.handle_response(command, %{command_class: :foo})
    end
  end
end
