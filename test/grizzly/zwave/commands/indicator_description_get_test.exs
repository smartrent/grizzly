defmodule Grizzly.ZWave.Commands.IndicatorDescriptionGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands

  test "encodes params correctly" do
    params = [indicator_id: :armed]
    {:ok, command} = Commands.create(:indicator_description_get, params)
    expected_params_binary = <<0x87, 0x06, 0x01>>
    assert expected_params_binary == Grizzly.encode_command(command)
  end

  test "decodes params correctly" do
    params_binary = <<0x87, 0x06, 0x02>>
    {:ok, cmd} = Grizzly.decode_command(params_binary)
    assert Keyword.get(cmd.params, :indicator_id) == :disarmed
  end
end
