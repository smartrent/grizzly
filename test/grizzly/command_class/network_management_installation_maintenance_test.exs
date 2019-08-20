defmodule Grizzly.CommandClass.NetworkManagementInstallationMaintenance.Test do
  use ExUnit.Case, async: true

  alias Grizzly.CommandClass.NetworkManagementInstallationMaintenance

  describe "decoding" do
    test "decoding speed" do
      assert :"9.6 kbit/sec" == NetworkManagementInstallationMaintenance.decode_speed(0x01)
      assert :"40 kbit/sec" == NetworkManagementInstallationMaintenance.decode_speed(0x02)
      assert :"100 kbit/sec" == NetworkManagementInstallationMaintenance.decode_speed(0x03)
      assert :unknown == NetworkManagementInstallationMaintenance.decode_speed(0x10)
    end
  end
end
