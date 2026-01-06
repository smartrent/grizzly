defmodule Grizzly.ZWave.Commands.S2KexSet do
  @moduledoc """
  During initial key exchange this command is used by an including node to grant
  network keys to a joining node. The joining node subsequently requests the
  granted keys once a temporary secure channel has been established.

  After establishment of the temporary secure channel, the joining node issues
  this command to the including node to securely state its intention to request
  the keys that were granted previously.
  """
  @behaviour Grizzly.ZWave.Command

  import Bitwise
  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Security2
  alias Grizzly.ZWave.Security

  @type param ::
          {:request_csa, boolean()}
          | {:echo, boolean()}
          | {:supported_kex_schemes, [Security2.kex_scheme()]}
          | {:supported_ecdh_profiles, [Security2.ecdh_profile()]}
          | {:granted_keys, [Security.key()]}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :s2_kex_set,
      command_byte: 0x06,
      command_class: Security2,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    request_csa = Command.param(command, :request_csa, false)
    echo = Command.param(command, :echo, false)
    supported_kex_schemes = Command.param(command, :supported_kex_schemes, [:kex_scheme_1])
    supported_ecdh_profiles = Command.param(command, :supported_ecdh_profiles, [:curve_25519])
    granted_keys = Command.param!(command, :granted_keys)

    <<0::6, bool_to_bit(request_csa)::1, bool_to_bit(echo)::1,
      encode_supported_kex_schemes(supported_kex_schemes)::8,
      encode_supported_ecdh_profiles(supported_ecdh_profiles)::8,
      Security.keys_to_byte(granted_keys)::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<_reserved::6, request_csa::1, echo::1, supported_kex_schemes::8,
          supported_ecdh_profiles::8, granted_keys::8>>
      ) do
    request_csa = bit_to_bool(request_csa)
    echo = bit_to_bool(echo)
    supported_kex_schemes = decode_supported_kex_schemes(supported_kex_schemes)
    supported_ecdh_profiles = decode_supported_ecdh_profiles(supported_ecdh_profiles)
    granted_keys = Security.byte_to_keys(granted_keys)

    {:ok,
     [
       {:request_csa, request_csa},
       {:echo, echo},
       {:supported_kex_schemes, supported_kex_schemes},
       {:supported_ecdh_profiles, supported_ecdh_profiles},
       {:granted_keys, granted_keys}
     ]}
  end

  @kex_scheme_1_mask 0b00000010

  defp encode_supported_kex_schemes(schemes) do
    if :kex_scheme_1 in schemes do
      @kex_scheme_1_mask
    else
      0
    end
  end

  defp decode_supported_kex_schemes(byte) do
    if band(byte, @kex_scheme_1_mask) == @kex_scheme_1_mask do
      {:ok, [:kex_scheme_1]}
    else
      {:ok, []}
    end
  end

  @curve_25519_mask 0b00000001

  defp encode_supported_ecdh_profiles(profiles) do
    if :curve_25519 in profiles do
      @curve_25519_mask
    else
      0
    end
  end

  defp decode_supported_ecdh_profiles(byte) do
    if band(byte, @curve_25519_mask) == @curve_25519_mask do
      {:ok, [:curve_25519]}
    else
      {:ok, []}
    end
  end
end
