defmodule Grizzly.NetworkKeys do
  @moduledoc false
  import Bitwise

  @type key_type ::
          :s0
          | :s2_unauthenticated
          | :s2_authenticated
          | :s2_access_control
          | :s2_authenticated_long_range
          | :s2_access_control_long_range
  @keys [
    {:s0, :s0, 0x80},
    {:s2_unauthenticated, :s2_unauthenticated, 1},
    {:s2_authenticated, :s2_authenticated, 2},
    {:s2_access_control, :s2_access, 4},
    {:s2_authenticated_long_range, :s2_authenticated_lr, 8},
    {:s2_access_control_long_range, :s2_access_lr, 16}
  ]

  # Only assigned, readable slots are exported. Never publish or log this result.
  def from_native(%{assigned_key_mask: mask} = keys) do
    for {name, field, bit} <- @keys,
        (mask &&& bit) != 0,
        value = Map.get(keys, field),
        is_binary(value) and byte_size(value) == 16 do
      {name, Base.encode16(value)}
    end
  end

  def zniffer(home_id, keys) when is_binary(home_id) and is_list(keys) do
    if length(keys) == 6 do
      """
      #{home_id}.txt:

      9F;#{keys[:s2_access_control]};1
      9F;#{keys[:s2_access_control_long_range]};1
      9F;#{keys[:s2_authenticated]};1
      9F;#{keys[:s2_authenticated_long_range]};1
      9F;#{keys[:s2_unauthenticated]};1
      98;#{keys[:s0]};1
      """
    end
  end

  def zniffer(_, _), do: nil
end
