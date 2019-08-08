defmodule Grizzly.CommandClass do
  @moduledoc """
  A Z-Wave Command Class
  """

  @type version :: non_neg_integer | :no_version_number
  @type name :: atom | nil
  @opaque t :: %__MODULE__{name: name, version: version}

  defstruct name: nil, version: :no_version_number

  @doc """
  Make a new command class
  """
  @spec new(opts :: keyword) :: t
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Get the name of a command class
  """
  @spec name(t()) :: name()
  def name(%__MODULE__{name: name}), do: name

  @doc """
  Get the version of the command class
  """
  @spec version(t()) :: version()
  def version(%__MODULE__{version: version}), do: version

  @doc """
  Check if the command class has a version
  """
  @spec versioned?(t) :: boolean
  def versioned?(%__MODULE__{version: version}) do
    version != :no_version_number
  end

  @doc """
  Set the version of the command
  """
  @spec set_version(t, non_neg_integer | :no_version_number) :: t
  def set_version(%__MODULE__{version: version} = command_class, version), do: command_class

  def set_version(%__MODULE__{} = command_class, version) when is_integer(version) do
    %__MODULE__{command_class | version: version}
  end
end
