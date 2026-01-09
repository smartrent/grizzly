defmodule Grizzly.ZWave.CommandClasses.Security2 do
  @moduledoc """
  Security 2 (S2) Command Class

  ### Definitions

  - **CKDF** - CMAC-based Key Derivation Function
  - **MEI** - Mutual Entropy Input
  - **SPAN** - Singlecast Pre-Agreed Nonce
  - **MPAN** - Multicast Pre-Agreed Nonce
  - **MGRP** - Multicast Group
  - **SOS** - Singlecast Out-of-Sync
  - **MOS** - Multicast Out-of-Sync
  """

  defmodule AAD do
    @moduledoc """
    S2 AAD (Additional Authenticated Data) structure
    """
    import Grizzly.ZWave.Encoding, only: [bool_to_bit: 1]

    @type t :: %__MODULE__{
            sender_node_id: non_neg_integer(),
            destination_tag: non_neg_integer(),
            home_id: non_neg_integer(),
            message_length: non_neg_integer(),
            sequence_number: non_neg_integer(),
            encrypted_extensions?: boolean(),
            extensions: binary()
          }

    defstruct sender_node_id: nil,
              destination_tag: nil,
              home_id: nil,
              message_length: nil,
              sequence_number: nil,
              encrypted_extensions?: false,
              extensions: <<>>

    @doc """
    Create a new S2 AAD struct.
    """
    def new(opts) do
      struct(__MODULE__, opts)
    end

    @doc """
    Encodes the AAD into a binary.
    """
    def encode(
          %__MODULE__{sender_node_id: sender_node_id, destination_tag: destination_tag} = aad
        )
        when sender_node_id > 255 or destination_tag > 255 do
      extensions? = if(aad.extensions != <<>>, do: true, else: false)

      <<sender_node_id::16, destination_tag::16, aad.home_id::32, aad.message_length::16,
        aad.sequence_number::8, 0::6, bool_to_bit(aad.encrypted_extensions?)::1,
        bool_to_bit(extensions?)::1, aad.extensions::binary>>
    end

    def encode(
          %__MODULE__{sender_node_id: sender_node_id, destination_tag: destination_tag} = aad
        ) do
      extensions? = if(aad.extensions != <<>>, do: true, else: false)

      <<sender_node_id::8, destination_tag::8, aad.home_id::32, aad.message_length::16,
        aad.sequence_number::8, 0::6, bool_to_bit(aad.encrypted_extensions?)::1,
        bool_to_bit(extensions?)::1, aad.extensions::binary>>
    end
  end

  @type kex_scheme :: :kex_scheme_1
  @type ecdh_profile :: :curve_25519

  # Key derivation functions

  @doc """
  Expands a network key into a CCM key for encryption and authorization, a
  personalization string, and an MPAN key using the CKDF-Expand algorithm as
  described in https://datatracker.ietf.org/doc/html/draft-moskowitz-hip-dex-02#section-6.3.
  """
  def generic_expand(network_key, constant_nk) do
    # ccm_key
    t0 = <<constant_nk::binary-size(15), 0x01>>
    ccm_key = aes_cmac_calculate(network_key, t0)

    # pstring first half
    t1 = <<ccm_key::binary-size(16), constant_nk::binary-size(15), 2::8>>
    pstring1 = aes_cmac_calculate(network_key, t1)

    # pstring second half
    t2 = <<pstring1::binary-size(16), constant_nk::binary-size(15), 3::8>>
    pstring2 = aes_cmac_calculate(network_key, t2)

    # MPAN key
    t3 = <<pstring2::binary-size(16), constant_nk::binary-size(15), 4::8>>
    mpan_key = aes_cmac_calculate(network_key, t3)

    {ccm_key, pstring1 <> pstring2, mpan_key}
  end

  @doc """
  Expands a network key into a CCM key for encryption and authorization, a
  personalization string, and an MPAN key using the CKDF-Expand algorithm as
  described in https://datatracker.ietf.org/doc/html/draft-moskowitz-hip-dex-02#section-6.3.
  """
  def network_key_expand(network_key) do
    generic_expand(network_key, :binary.copy(<<0x55>>, 16))
  end

  @doc """
  Expands a temporary network key into a CCM key for encryption and authorization, a
  personalization string, and an MPAN key using the CKDF-Expand algorithm as
  described in https://datatracker.ietf.org/doc/html/draft-moskowitz-hip-dex-02#section-6.3.
  """
  def temp_key_expand(prk) do
    generic_expand(prk, :binary.copy(<<0x88>>, 16))
  end

  @spec temp_key_extract(<<_::256>>, <<_::256>>, <<_::256>>) :: <<_::128>>
  def temp_key_extract(ecdh_shared_secret, sender_pubkey, receiver_pubkey) do
    constant_prk = :binary.copy(<<0x33>>, 16)

    aes_cmac_calculate(constant_prk, ecdh_shared_secret <> sender_pubkey <> receiver_pubkey)
    |> binary_slice(0..15)
  end

  @doc """
  Mix and expand the sender and receiver entropy inputs into a nonce using CKDF-MEI.
  """
  @spec ckdf_mei_expand(<<_::128>>, <<_::128>>) :: <<_::256>>
  def ckdf_mei_expand(sender_entropy_input, receiver_entropy_input) do
    # Extract nonce PRK
    constant_nonce = :binary.copy(<<0x26>>, 16)
    nonce_prk = aes_cmac_calculate(constant_nonce, sender_entropy_input <> receiver_entropy_input)

    # Expand nonce PRK
    const_entropy_input = :binary.copy(<<0x88>>, 15)

    t0 = const_entropy_input <> <<0x00>>
    t1 = aes_cmac_calculate(nonce_prk, t0 <> const_entropy_input <> <<0x01>>)
    t2 = aes_cmac_calculate(nonce_prk, t1 <> const_entropy_input <> <<0x02>>)

    t1 <> t2
  end

  @doc """
  Encode the ECDH public key into a DSK string.
  """
  def ecdh_public_key_to_dsk_string(public_key) do
    for <<int::16 <- public_key>>, into: [] do
      Integer.to_string(int) |> String.pad_leading(5, "0")
    end
    |> Enum.join("-")
  end

  @doc """
  Computes an ECDH public key for the given private key.
  """
  def ecdh_public_key(private_key) do
    {pub_key, _} = :crypto.generate_key(:ecdh, :x25519, private_key)
    pub_key
  end

  @doc """
  Computes the shared secret using the ECDH algorithm with the local node's
  private key and the remote node's public key (as reported by S2 Public Key Report).
  """
  def ecdh_shared_secret(private_key, remote_public_key) do
    :crypto.compute_key(:ecdh, remote_public_key, private_key, :x25519)
  end

  defp aes_cmac_calculate(key, message) do
    :crypto.mac(:cmac, :aes_128_cbc, key, message)
  end
end
