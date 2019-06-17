defmodule Grizzly.CommandClass do
  @moduledoc """
  Identifies a command class by name and version
  """

  alias __MODULE__

  @type version :: non_neg_integer | :no_version_number
  @type name :: atom
  @type t :: %__MODULE__{name: name, version: version}

  defstruct name: nil, version: :no_version_number

  @spec new(opts :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @spec versioned?(t) :: boolean
  def versioned?(%CommandClass{version: version}) do
    version != :no_version_number
  end

  @spec set_version(t, non_neg_integer | :no_version_number) :: t
  def set_version(%CommandClass{} = command_class, version) when is_integer(version) do
    %CommandClass{command_class | version: version}
  end

  def set_version(%CommandClass{} = command_class, :no_version_number) do
    command_class
  end
end
