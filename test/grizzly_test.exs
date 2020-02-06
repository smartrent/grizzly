defmodule Grizzly.Test do
  use ExUnit.Case

  test "sending a command" do
    assert :ok == Grizzly.send_command(2, :switch_binary_set, value: :on)
  end
end
