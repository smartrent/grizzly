defmodule Grizzly.FirmwareUpdates.FirmwareUpdateRunner.Image do
  @moduledoc false

  @type t :: %__MODULE__{path: String.t(), fragments: [binary]}

  require Logger

  defstruct path: nil,
            fragments: []

  @spec new(String.t()) :: t()
  def new(path) do
    %__MODULE__{path: path}
  end

  @doc "Fragment the entire image or (ASSUMPTION) the yet-to-be-uploaded portion of the image"
  def fragment_image(
        %__MODULE__{fragments: fragments} = image,
        max_fragment_size,
        next_fragment_index
      ) do
    if next_fragment_index == 1 do
      fragments = break_into_fragments(image.path, max_fragment_size)
      %__MODULE__{image | fragments: fragments}
    else
      # enums are zero-indexed, zwave is one-indexed
      {uploaded_fragments, remaining_fragments} = Enum.split(fragments, next_fragment_index - 1)

      new_remaining_fragments =
        Enum.reduce(remaining_fragments, <<>>, &(&2 <> &1))
        |> Enum.chunk_every(max_fragment_size)
        |> Enum.into([])

      %__MODULE__{image | fragments: uploaded_fragments ++ new_remaining_fragments}
    end
  end

  @spec data(Grizzly.FirmwareUpdates.FirmwareUpdateRunner.Image.t(), non_neg_integer) ::
          {false, binary} | {true, binary}
  def data(
        %__MODULE__{fragments: fragments},
        fragment_index
      ) do
    # fragment indexing by ZWave is 1-based
    fragment = Enum.at(fragments, fragment_index - 1)
    last? = fragment_index == Enum.count(fragments)
    {last?, fragment}
  end

  def fragment_count(%__MODULE__{fragments: fragments}) do
    Enum.count(fragments)
  end

  defp break_into_fragments(path, fragment_size) do
    File.stream!(path, [], fragment_size)
    |> Enum.into([])
  end
end
