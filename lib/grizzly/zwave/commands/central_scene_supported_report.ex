defmodule Grizzly.ZWave.Commands.CentralSceneSupportedReport do
  @moduledoc """
  This command is used to report the maximum number of supported scenes and the
  Key Attributes supported for each scene.

  Versions 1 and 2 are obsolete. Version 3+ fields are required.

  Params:

    * `:supported_scenes` - This field indicates the maximum number of scenes
      supported by the requested device. (required)

    * `:slow_refresh_support` - This field indicates whether the node supports
      the Slow Refresh capability. (required)

    * `:identical` - This field indicates if all scenes are supporting the same
      Key Attributes (required)

    * `:bit_mask_bytes` - This field advertises the size of each “Supported Key Attributes”
      field measured in bytes. Must be 1..3. (required)

    * `:supported_key_attributes` - This field advertises the attributes supported
      by the corresponding scene (required)
      * A list of lists of key attributes where a key attribute is one of
        `:key_pressed_1_time` | `:key_released` | `:key_held_down` | `:key_pressed_2_times`
        | `:key_pressed_3_times` | `:key_pressed_4_times` | `:key_pressed_5_times`.
      * If not identical, the first list of key attributes corresponds to scene 1, the
        second to scene 2 etc. for each of supported_scenes
      * If identical, only the key attributes of scene 1 are to be listed

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.CentralScene
  alias Grizzly.ZWave.DecodeError

  # give me some type specs for your params
  @type param ::
          {:supported_scenes, non_neg_integer}
          | {:slow_refresh_support, boolean}
          | {:identical, boolean}
          | {:bit_mask_bytes, 1..3}
          | {:supported_key_attributes, [CentralScene.key_attributes()]}
  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    supported_scenes = Command.param!(command, :supported_scenes)
    identical? = Command.param!(command, :identical)
    identical_bit = identical? |> bool_to_bit()

    slow_refresh_support_bit =
      Command.param!(command, :slow_refresh_support) |> bool_to_bit()

    bit_mask_bytes = Command.param!(command, :bit_mask_bytes)

    supported_key_attributes =
      Command.param!(command, :supported_key_attributes)
      |> CentralScene.validate_supported_key_attributes(supported_scenes, identical?)

    supported_key_attributes_binary =
      supported_key_attributes_to_binary(bit_mask_bytes, supported_key_attributes)

    <<supported_scenes, slow_refresh_support_bit::1, 0x00::4, bit_mask_bytes::2,
      identical_bit::1>> <> supported_key_attributes_binary
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<supported_scenes, slow_refresh_support_bit::1, 0x00::4, bit_mask_bytes::2,
          identical_bit::1, supported_key_attributes_binary::binary>>
      ) do
    identical? = identical_bit == 1

    with {:ok, supported_key_attributes} <-
           supported_key_attributes_from_binary(
             supported_key_attributes_binary,
             supported_scenes,
             bit_mask_bytes,
             identical?
           ) do
      {:ok,
       [
         supported_scenes: supported_scenes,
         slow_refresh_support: slow_refresh_support_bit == 1,
         identical: identical?,
         bit_mask_bytes: bit_mask_bytes,
         supported_key_attributes: supported_key_attributes
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  defp supported_key_attributes_to_binary(bit_mask_bytes, supported_key_attributes) do
    Enum.reduce(supported_key_attributes, <<>>, fn scene_key_attributes, acc ->
      acc <> key_attributes_bit_masks_binary(bit_mask_bytes, scene_key_attributes)
    end)
  end

  defp key_attributes_bit_masks_binary(bit_mask_bytes, scene_key_attributes) do
    # [{byte_index, bit_index}, ...]
    bit_indices =
      for key_attribute <- scene_key_attributes,
          do: CentralScene.key_attribute_to_bit_index(key_attribute)

    # [[1,4,5], [], []]
    byte_bit_indices =
      for i <- 1..bit_mask_bytes do
        Enum.reduce(bit_indices, [], fn {byte_index, bit_index}, acc ->
          if byte_index == i, do: [bit_index | acc], else: acc
        end)
      end

    # [<<128>>, <<>>, <<>>]
    bit_masks =
      for per_byte_bit_indices <- byte_bit_indices do
        for bit_index <- 7..0//-1, into: <<>> do
          if bit_index in per_byte_bit_indices, do: <<1::1>>, else: <<0::1>>
        end
      end

    # <<...>>
    for bit_mask <- bit_masks, into: <<>>, do: bit_mask
  end

  defp supported_key_attributes_from_binary(
         supported_key_attributes_binary,
         supported_scenes,
         bit_mask_bytes,
         identical?
       ) do
    # [ [0,2,3], [], [1,4], ...]
    # [[4, 3, 2, 1, 0], [], [], []]
    all_bit_masks_as_lists = bit_masks_from_binary(supported_key_attributes_binary)
    # [ [ [0,2,3], [] ], ...]
    per_scene_bit_indices = Enum.chunk_every(all_bit_masks_as_lists, bit_mask_bytes)
    scene_count = Enum.count(per_scene_bit_indices)

    # Some devices may return more than one set of scene bit indices though they are meant to
    # identical (the superfluous will be ignored)
    valid? = if identical?, do: scene_count >= 1, else: scene_count == supported_scenes

    if valid? do
      per_scene_bit_indices =
        if identical? do
          Enum.take(per_scene_bit_indices, 1)
        else
          per_scene_bit_indices
        end

      supported_key_attributes =
        for scene_bit_indices <- per_scene_bit_indices do
          # [{[0,2,3], 1}, {[], 2}]
          byte_indexed_scene_bit_indices = Enum.with_index(scene_bit_indices, 1)

          Enum.reduce(
            byte_indexed_scene_bit_indices,
            [],
            fn {bit_indices, byte_index}, acc ->
              attribute_keys = attribute_keys_from_bit_indices(bit_indices, byte_index)
              acc ++ attribute_keys
            end
          )
          |> List.flatten()
        end

      {:ok, supported_key_attributes}
    else
      {:error,
       %DecodeError{
         param: :supported_key_attributes,
         value: supported_key_attributes_binary,
         command: :central_scene_supported_report
       }}
    end
  end

  defp bit_masks_from_binary(supported_key_attributes_binary) do
    for byte <- :erlang.binary_to_list(supported_key_attributes_binary) do
      indexed_bit_list =
        for(<<(bit::1 <- <<byte>>)>>, do: bit) |> Enum.reverse() |> Enum.with_index()

      Enum.reduce(
        indexed_bit_list,
        [],
        fn {bit, bit_index}, acc ->
          case bit do
            0 -> acc
            1 -> [bit_index | acc]
          end
        end
      )
    end
  end

  defp attribute_keys_from_bit_indices(bit_indices, byte_index) do
    for(
      bit_index <- bit_indices,
      do: CentralScene.key_attribute_from_bit_index(byte_index, bit_index)
    )
    |> Enum.reject(&(&1 == :ignore))
  end
end
