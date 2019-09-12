defmodule Grizzly.CommandClass.NetworkManagementInclusion do
  @type node_neighbor_update_status :: :done | :failed
  @type add_mode :: :any | :stop | :any_s2
  @type remove_mode :: :any | :stop
  @type accept_byte :: 0x00 | 0x01
  @type add_mode_byte :: 0x01 | 0x05 | 0x07
  @type remove_mode_byte :: 0x01 | 0x05
  @type csa_byte :: 0x00 | 0x02

  @spec encode_add_mode(add_mode() | add_mode_byte()) ::
          {:ok, add_mode_byte()} | {:error, :invalid_arg, any()}
  def encode_add_mode(:any), do: {:ok, 0x01}
  def encode_add_mode(:stop), do: {:ok, 0x05}
  def encode_add_mode(:any_s2), do: {:ok, 0x07}
  def encode_add_mode(byte) when byte in [1, 5, 7], do: {:ok, byte}
  def encode_add_mode(arg), do: {:error, :invalid_arg, arg}

  @spec encode_remove_mode(remove_mode() | remove_mode_byte()) ::
          {:ok, remove_mode_byte()} | {:error, :invalid_arg, any()}
  def encode_remove_mode(:any), do: {:ok, 0x01}
  def encode_remove_mode(:stop), do: {:ok, 0x05}
  def encode_remove_mode(byte) when byte in [0x01, 0x05], do: {:ok, byte}
  def encode_remove_mode(arg), do: {:error, :invalid_arg, arg}

  @spec encode_accept(boolean) :: {:ok, accept_byte} | {:error, :invalid_arg, any()}
  def encode_accept(true), do: {:ok, 0x01}
  def encode_accept(false), do: {:ok, 0x00}
  def encode_accept(arg), do: {:error, :invalid_arg, arg}

  @spec encode_csa(boolean) :: {:ok, csa_byte} | {:error, :invalid_arg, any()}
  def encode_csa(true), do: {:ok, 0x02}
  def encode_csa(false), do: {:ok, 0x00}
  def encode_csa(arg), do: {:error, :invalid_arg, arg}

  @spec encode_accept_s2_bootstrapping(boolean) ::
          {:ok, accept_byte} | {:error, :invalid_arg, any()}
  def encode_accept_s2_bootstrapping(true), do: {:ok, 0x01}
  def encode_accept_s2_bootstrapping(false), do: {:ok, 0x00}
  def encode_accept_s2_bootstrapping(arg), do: {:error, :invalid_arg, arg}

  @spec decode_node_neighbor_update_status(0x22 | 0x23) :: node_neighbor_update_status
  def decode_node_neighbor_update_status(0x22), do: :done
  def decode_node_neighbor_update_status(0x23), do: :failed
end
