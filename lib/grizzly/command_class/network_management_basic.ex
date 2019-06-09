defmodule Grizzly.CommandClass.NetworkManagementBasic do
  @type default_set_status :: :done | :busy
  @type learn_mode_status :: :done | :failed | :failed_security

  @spec decode_default_set_status(0x06 | 0x07) :: default_set_status
  def decode_default_set_status(0x06), do: :done
  def decode_default_set_status(0x07), do: :busy

  @spec decode_learn_mode_set_status(0x06 | 0x07 | 0x09, non_neg_integer) :: %{
          status: learn_mode_status(),
          new_node_id: non_neg_integer()
        }
  def decode_learn_mode_set_status(0x06, new_node_id) do
    %{status: :done, new_node_id: new_node_id}
  end

  def decode_learn_mode_set_status(0x07, _new_node_id) do
    %{status: :failed, new_node_id: 0}
  end

  def decode_learn_mode_set_status(0x09, _new_node_id) do
    %{status: :security_failed, new_node_id: 0}
  end
end
