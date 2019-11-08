defmodule Grizzly.CommandClass.NetworkManagementBasic do
  alias Grizzly.DSK

  @type default_set_status :: :done | :busy
  @type learn_mode_status :: :done | :failed | :failed_security
  @type learn_mode :: :enable | :disable | :enable_routed
  @type learn_mode_byte :: 0x00 | 0x01 | 0x02
  @type add_mode :: :learn | :add
  @type add_mode_byte :: 0x00 | 0x01

  @type dsk_get_report :: %{
          add_mode: add_mode(),
          dsk: binary()
        }

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

  @doc """
  Encode the add mode `:learn` or `:add` into a byte
  """
  @spec encode_add_mode(add_mode()) :: {:ok, add_mode_byte()} | {:error, :invalid_arg, any()}
  def encode_add_mode(:learn), do: {:ok, 0x00}
  def encode_add_mode(:add), do: {:ok, 0x01}
  def encode_add_mode(other), do: {:error, :invalid_arg, other}

  @doc """
  Take the byte of the add mode and decode it into `:learn` or `:add`.
  """
  @spec add_mode_from_byte(byte()) :: add_mode()
  def add_mode_from_byte(byte) do
    <<_::size(7), add_mode_bit::size(1)>> = <<byte>>

    case add_mode_bit do
      0 ->
        :learn

      1 ->
        :add
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

  @doc """
  Decode the bytestring that is returned from Z-Wave that has the DSK
  report
  """
  @spec decode_dsk_report(binary()) :: dsk_get_report()
  def decode_dsk_report(<<add_mode, dsk::binary-size(16)>>) do
    {:ok, dsk} = DSK.binary_to_string(dsk)

    %{
      add_mode: add_mode_from_byte(add_mode),
      dsk: dsk
    }
  end
end
