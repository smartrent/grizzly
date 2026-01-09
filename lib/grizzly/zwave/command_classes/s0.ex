defmodule Grizzly.ZWave.CommandClasses.S0 do
  @moduledoc """
  S0 (Security) Command Class
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x98

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :security

  @authentication_vector <<0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55,
                           0x55, 0x55, 0x55, 0x55>>

  @doc """
  Derive the S0 authentication key (for calculating MACs) from the network key.

  This is done by encrypting the S0 authentication vector (0x55 repeated 16
  times) with the network key using AES-128-ECB.
  """
  @spec authentication_key(<<_::128>>) :: <<_::128>>
  def authentication_key(network_key) do
    :crypto.crypto_one_time(:aes_128_ecb, network_key, @authentication_vector, encrypt: true)
  end

  @encryption_vector <<0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA,
                       0xAA, 0xAA, 0xAA, 0xAA>>

  @doc """
  Derive the S0 encryption key (for calculating MACs) from the network key.

  This is done by encrypting the S0 encryption vector (0xAA repeated 16
  times) with the network key using AES-128-ECB.
  """
  @spec encryption_key(<<_::128>>) :: <<_::128>>
  def encryption_key(network_key) do
    :crypto.crypto_one_time(:aes_128_ecb, network_key, @encryption_vector, encrypt: true)
  end

  @mac_iv <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

  def encrypt(network_key, sender_nonce, receiver_nonce, payload) do
    do_encrypt_decrypt(network_key, sender_nonce, receiver_nonce, payload, true)
  end

  def decrypt(network_key, sender_nonce, receiver_nonce, payload) do
    do_encrypt_decrypt(network_key, sender_nonce, receiver_nonce, payload, false)
  end

  defp do_encrypt_decrypt(network_key, sender_nonce, receiver_nonce, payload, encrypt?) do
    network_encryption_key = encryption_key(network_key)

    iv = <<sender_nonce::binary-size(8), receiver_nonce::binary-size(8)>>

    :crypto.crypto_one_time(:aes_128_ofb, network_encryption_key, iv, payload,
      encrypt: encrypt?,
      padding: :zero
    )
  end

  @doc """
  Calculates the MAC for an S0 Message Encapsulation command.

  First, a block of authorization data is created by concatenating the following
  values: the IV, the command byte (0x81 or 0xC1), the sender node ID, the receiver
  node ID, the length of the encrypted payload, and the encrypted payload itself.

  The IV is constructed by concatenating the sender nonce (which is included in
  the command -- in the spec, this is the "initialization vector" field) with
  the receiver nonce (which was obtained via a Nonce Get/Report exchange).

  Because this is unclear in the docs, it is important to note that the sequencing
  byte (which includes the second frame, sequenced, and sequence counter fields)
  is part of the encrypted payload, which is why it isn't included in the auth
  data block.

  The auth data block is then padded to the block size (16 bytes for AES-128) and
  then encrypted in 16-byte blocks using the network authentication key (see
  `authentication_key/1`). The IV used for the first block is 16 bytes of 0x00,
  and the IV for each subsequent block is the output from the previous block.

  The MAC is the first 8 bytes of the final block.
  """
  @spec calculate_mac(
          network_key :: <<_::128>>,
          command_byte :: 0x81 | 0xC1,
          sender_node_id :: pos_integer(),
          receiver_node_id :: pos_integer(),
          sender_nonce :: <<_::64>>,
          receiver_nonce :: <<_::64>>,
          encrypted_payload :: binary()
        ) :: <<_::64>>
  def calculate_mac(
        network_key,
        command_byte,
        sender_node_id,
        receiver_node_id,
        sender_nonce,
        receiver_nonce,
        encrypted_payload
      ) do
    network_auth_key = authentication_key(network_key)

    iv = <<sender_nonce::binary-size(8), receiver_nonce::binary-size(8)>>

    auth_data =
      pad_to_block_size(
        <<iv::binary-size(16), command_byte::8, sender_node_id::8, receiver_node_id::8,
          byte_size(encrypted_payload)::8, encrypted_payload::binary>>
      )

    for <<block::binary-size(16) <- auth_data>>, reduce: @mac_iv do
      iv ->
        :crypto.crypto_one_time(:aes_128_cbc, network_auth_key, iv, block, encrypt: true)
    end
    |> binary_slice(0..7)
  end

  # We used a fixed block size here because S0 only uses AES-128.
  defp pad_to_block_size(data) do
    padding = 16 - rem(byte_size(data), 16)
    <<data::binary-size(byte_size(data)), 0::padding*8>>
  end
end
