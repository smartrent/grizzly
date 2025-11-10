defmodule Grizzly.FirmwareUpdates.OTW.UpdateSpec do
  @moduledoc """
  A firmware upgrade specification used to determine if a firmware image can
  be applied given the running firmware version.
  """

  @typedoc """
  Firmware upgrade specification.

  * `version` - the version of the firmware image
  * `path` - the path to the firmware image
  * `applies_to` - the version requirement for the running firmware version
    that must be met for the upgrade to be applied
  """
  @type t :: %__MODULE__{
          version: Version.t(),
          path: Path.t(),
          applies_to: Version.requirement()
        }

  @enforce_keys [:version, :path, :applies_to]
  defstruct [:version, :path, :applies_to]

  @spec new(map() | keyword()) :: t()
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @doc "Whether the spec applies given the current version."
  @spec applies?(t(), Version.t()) :: boolean()
  def applies?(%__MODULE__{} = spec, current_version) do
    # Only upgrades apply -- with the default bootloader, it's not possible to
    # downgrade or re-apply the same version.
    Version.compare(current_version, spec.version) == :lt &&
      Version.match?(current_version, spec.applies_to)
  end
end
