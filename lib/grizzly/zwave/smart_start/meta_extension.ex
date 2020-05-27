defmodule Grizzly.ZWave.SmartStart.MetaExtension do
  @moduledoc """
  Meta Extension support for SmartRent devices
  """

  alias Grizzly.ZWave.SmartStart.MetaExtension.{
    AdvancedJoining,
    BootstrappingMode,
    LocationInformation,
    MaxInclusionRequestInterval,
    NameInformation,
    NetworkStatus,
    ProductId,
    ProductType,
    SmartStartInclusionSetting,
    UUID16
  }

  @type t ::
          AdvancedJoining.t()
          | BootstrappingMode.t()
          | LocationInformation.t()
          | MaxInclusionRequestInterval.t()
          | NameInformation.t()
          | NetworkStatus.t()
          | ProductId.t()
          | ProductType.t()
          | SmartStartInclusionSetting.t()
          | UUID16.t()

  @callback to_binary(t()) :: {:ok, binary()}

  @callback from_binary(binary()) :: {:ok, t()} | {:error, reason :: any()}

  @doc """
  Given a binary string with meta extensions, can be in any order, decode it
  and return a list of `MetaExtension.t()`
  """
  @spec extensions_from_binary(binary) ::
          {:ok, [t()]}
          | {:error, :invalid_meta_extensions_binary}
          | {:error, module(), reason :: any()}
  def extensions_from_binary(binary) do
    with {:ok, binary_list} <- binary_extensions_to_list(binary),
         extensions when is_list(extensions) <- binary_list_into_extension_list(binary_list) do
      {:ok, extensions}
    end
  end

  @doc """
  Take a list of `Extension.t()`s and turn them into a binary string
  """
  @spec extensions_to_binary([t()]) :: binary()
  def extensions_to_binary(extension_list) do
    extension_list
    |> Enum.reduce(<<>>, fn extension, binary ->
      binary <> extension_to_binary(extension)
    end)
  end

  @doc """
  Take an `Extension.t()` and turn it into a binary
  """
  @spec extension_to_binary(t()) :: binary()
  def extension_to_binary(extension) do
    ex_module = extension_module_from_struct(extension)
    {:ok, ex_binary} = apply(ex_module, :to_binary, [extension])
    ex_binary
  end

  defp binary_extensions_to_list("") do
    {:ok, []}
  end

  defp binary_extensions_to_list(binary) do
    case get_extension(binary) do
      {:ok, {extension, ""}} ->
        {:ok, [extension]}

      {:ok, {extension, rest}} ->
        binary_extensions_to_list(rest, [extension])

      error ->
        error
    end
  end

  defp binary_extensions_to_list(binary, extensions) do
    case get_extension(binary) do
      {:ok, {extension, ""}} ->
        {:ok, [extension | extensions]}

      {:ok, {extension, rest}} ->
        binary_extensions_to_list(rest, [extension | extensions])

      error ->
        error
    end
  end

  defp get_extension(<<extension_byte, length, args::binary-size(length), rest::binary>>) do
    {:ok, {<<extension_byte, length>> <> args, rest}}
  end

  defp get_extension(bin) when is_binary(bin) do
    {:error, :invalid_meta_extensions_binary}
  end

  defp binary_list_into_extension_list(binary_list) do
    Enum.reduce_while(binary_list, [], fn extension_binary, extensions ->
      case try_extension_from_binary(extension_binary) do
        {:ok, extension} ->
          {:cont, [extension | extensions]}

        error ->
          {:halt, error}
      end
    end)
  end

  defp try_extension_from_binary(binary) do
    default_error = {:error, :invalid_meta_extensions_binary}

    [
      AdvancedJoining,
      BootstrappingMode,
      LocationInformation,
      MaxInclusionRequestInterval,
      NameInformation,
      NetworkStatus,
      ProductId,
      ProductType,
      SmartStartInclusionSetting,
      UUID16
    ]
    |> Enum.reduce_while(default_error, fn extension_module, error ->
      case extension_module.from_binary(binary) do
        {:ok, extension} ->
          {:halt, {:ok, extension}}

        {:error, :invalid_binary} ->
          {:cont, error}

        {:error, decode_error} ->
          {:halt, {:error, extension_module, decode_error}}
      end
    end)
  end

  defp extension_module_from_struct(%AdvancedJoining{}), do: AdvancedJoining
  defp extension_module_from_struct(%BootstrappingMode{}), do: BootstrappingMode
  defp extension_module_from_struct(%LocationInformation{}), do: LocationInformation

  defp extension_module_from_struct(%MaxInclusionRequestInterval{}),
    do: MaxInclusionRequestInterval

  defp extension_module_from_struct(%NameInformation{}), do: NameInformation
  defp extension_module_from_struct(%NetworkStatus{}), do: NetworkStatus
  defp extension_module_from_struct(%ProductId{}), do: ProductId
  defp extension_module_from_struct(%ProductType{}), do: ProductType
  defp extension_module_from_struct(%SmartStartInclusionSetting{}), do: SmartStartInclusionSetting
  defp extension_module_from_struct(%UUID16{}), do: UUID16
end
