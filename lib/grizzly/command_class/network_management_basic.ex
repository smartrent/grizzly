defmodule Grizzly.CommandClass.NetworkManagementBasic do
  @type default_set_status :: :done | :busy
  @type learn_mode_status :: :done | :failed | :failed_security
  @type learn_mode :: :enable | :disable | :enable_routed
  @type learn_mode_byte :: 0x00 | 0x01 | 0x02

  @spec encode_learn_mode(learn_mode) :: {:ok, learn_mode_byte} | {:error, :invalid_arg, any()}
  def encode_learn_mode(mode) do
    case mode do
      # ZW_SET_LEARN_MODE_CLASSIC - accept inclusion in direct range only
      :enable -> {:ok, 0x01}
      # ZW_SET_LEARN_MODE_DISABLE - stop learn mode
      :disable -> {:ok, 0x00}
      # ZW_SET_LEARN_MODE_NWI - accept routed inclusion
      :enable_routed -> {:ok, 0x02}
      other -> {:error, :invalid_arg, other}
    end
  end

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
