defmodule Grizzly.CommandClass do
  @moduledoc """
  Identifies a command class by name and version
  """

  @type version :: non_neg_integer | :no_version_number
  @type name :: atom
  @type t :: %__MODULE__{name: name, version: version}

  defstruct name: nil, version: :no_version_number

  @spec new(opts :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @spec name(t()) :: name()
  def name(%__MODULE__{name: name}), do: name

  @spec version(t()) :: version()
  def version(%__MODULE__{version: version}), do: version

  @spec versioned?(t) :: boolean
  def versioned?(%__MODULE__{version: version}) do
    version != :no_version_number
  end

  @spec set_version(t, non_neg_integer | :no_version_number) :: t
  def set_version(%__MODULE__{version: version} = command_class, version), do: command_class

  def set_version(%__MODULE__{} = command_class, version) when is_integer(version) do
    %__MODULE__{command_class | version: version}
  end
end
