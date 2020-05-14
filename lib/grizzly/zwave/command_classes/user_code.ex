defmodule Grizzly.ZWave.CommandClasses.UserCode do
  @moduledoc """
  Command Class for working with user codes
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.DecodeError

  @type user_id_status :: :occupied | :available | :reserved_by_admin | :status_not_available

  @impl true
  def byte(), do: 0x63

  @impl true
  def name(), do: :user_code

  @spec user_id_status_to_byte(user_id_status()) :: byte()
  def user_id_status_to_byte(:available), do: 0x00
  def user_id_status_to_byte(:occupied), do: 0x01
  def user_id_status_to_byte(:reversed_by_admin), do: 0x02
  def user_id_status_to_byte(:status_not_available), do: 0xFE

  @spec user_id_status_from_byte(byte()) :: {:ok, user_id_status()} | {:error, DecodeError.t()}
  def user_id_status_from_byte(0x00), do: {:ok, :available}
  def user_id_status_from_byte(0x01), do: {:ok, :occupied}
  def user_id_status_from_byte(0x02), do: {:ok, :reversed_by_admin}
  def user_id_status_from_byte(0xFE), do: {:ok, :status_not_available}

  def user_id_status_from_byte(byte),
    do: {:error, %DecodeError{value: byte, param: :user_id_status, command: :user_code_set}}
end
