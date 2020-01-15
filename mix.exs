defmodule Grizzly.MixProject do
  use Mix.Project

  def project do
    [
      app: :grizzly,
      version: "0.8.2",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :asn1, :public_key, :ssl],
      mod: {Grizzly.Application, []}
    ]
  end

  def elixirc_paths(:test), do: ["test/support", "lib"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:test, :dev], runtime: false},
      {:muontrap, "~> 0.4"},
      {:ex_doc, "~> 0.19", only: [:test, :dev], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      ignore_warnings: "dialyzer.ignore-warnings",
      flags: [:unmatched_returns, :error_handling, :race_conditions]
    ]
  end

  defp description do
    "Z-Wave Z/IP gateway client"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/smartrent/grizzly"}
    ]
  end

  defp docs() do
    [
      extras: ["README.md"],
      main: "readme",
      logo: "./assets/grizzly-icon-yellow.png",
      source_url: "https://github.com/smartrent/grizzly",
      groups_for_modules: [
        "Command Classes": [
          Grizzly.CommandClass,
          Grizzly.CommandClass.Association,
          Grizzly.CommandClass.AssociationGroupInfo,
          Grizzly.CommandClass.Basic,
          Grizzly.CommandClass.Battery,
          Grizzly.CommandClass.CommandClassVersion,
          Grizzly.CommandClass.Configuration,
          Grizzly.CommandClass.DoorLock,
          Grizzly.CommandClass.FirmwareUpdateMD,
          Grizzly.CommandClass.Mailbox,
          Grizzly.CommandClass.ManufacturerSpecific,
          Grizzly.CommandClass.Meter,
          Grizzly.CommandClass.MultilevelSensor,
          Grizzly.CommandClass.MultiChannelAssociation,
          Grizzly.CommandClass.NetworkManagementBasic,
          Grizzly.CommandClass.NetworkManagementInclusion,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance,
          Grizzly.CommandClass.NetworkManagementProxy,
          Grizzly.CommandClass.NoOperation,
          Grizzly.CommandClass.Notification,
          Grizzly.CommandClass.Powerlevel,
          Grizzly.CommandClass.ScheduleEntryLock,
          Grizzly.CommandClass.SensorMultilevel,
          Grizzly.CommandClass.SwitchBinary,
          Grizzly.CommandClass.SwitchMultilevel,
          Grizzly.CommandClass.ThermostatFanMode,
          Grizzly.CommandClass.ThermostatFanState,
          Grizzly.CommandClass.ThermostatMode,
          Grizzly.CommandClass.ThermostatSetback,
          Grizzly.CommandClass.ThermostatSetpoint,
          Grizzly.CommandClass.UserCode,
          Grizzly.CommandClass.Version,
          Grizzly.CommandClass.WakeUp,
          Grizzly.CommandClass.ZwaveplusInfo
        ],
        Commands: [
          Grizzly.Command,
          Grizzly.CommandClass.Association.Get,
          Grizzly.CommandClass.Association.Remove,
          Grizzly.CommandClass.Association.Set,
          Grizzly.CommandClass.Association.SupportedGroupingsGet,
          Grizzly.CommandClass.AssociationGroupInfo.GroupNameGet,
          Grizzly.CommandClass.AssociationGroupInfo.GroupInfoGet,
          Grizzly.CommandClass.AssociationGroupInfo.GroupCommandListGet,
          Grizzly.CommandClass.Basic.Get,
          Grizzly.CommandClass.Basic.Set,
          Grizzly.CommandClass.Battery.Get,
          Grizzly.CommandClass.Configuration.BulkGet,
          Grizzly.CommandClass.Configuration.Get,
          Grizzly.CommandClass.Configuration.Set,
          Grizzly.CommandClass.DoorLock.OperationGet,
          Grizzly.CommandClass.DoorLock.OperationSet,
          Grizzly.CommandClass.FirmwareUpdateMD.Get,
          Grizzly.CommandClass.FirmwareUpdateMD.Set,
          Grizzly.CommandClass.Mailbox.ConfigurationGet,
          Grizzly.CommandClass.ManufacturerSpecific.DeviceSpecificGet,
          Grizzly.CommandClass.ManufacturerSpecific.Get,
          Grizzly.CommandClass.Meter.Get,
          Grizzly.CommandClass.MultiChannelAssociation.Get,
          Grizzly.CommandClass.MultiChannelAssociation.Remove,
          Grizzly.CommandClass.MultiChannelAssociation.Set,
          Grizzly.CommandClass.MultiChannelAssociation.SupportedGroupingsGet,
          Grizzly.CommandClass.NetworkManagementBasic.DefaultSet,
          Grizzly.CommandClass.NetworkManagementBasic.DSKGet,
          Grizzly.CommandClass.NetworkManagementBasic.LearnModeSet,
          Grizzly.CommandClass.NetworkManagementInclusion.NodeAdd,
          Grizzly.CommandClass.NetworkManagementInclusion.NodeAddDSKSet,
          Grizzly.CommandClass.NetworkManagementInclusion.NodeAddKeysSet,
          Grizzly.CommandClass.NetworkManagementInclusion.NodeNeighborUpdateRequest,
          Grizzly.CommandClass.NetworkManagementInclusion.NodeRemove,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance.PriorityRouteGet,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance.PriorityRouteGet,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance.RSSIGet,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance.StatisticsClear,
          Grizzly.CommandClass.NetworkManagementInstallationMaintenance.StatisticsGet,
          Grizzly.CommandClass.NetworkManagementProxy.NodeInfoCache,
          Grizzly.CommandClass.NetworkManagementProxy.NodeListGet,
          Grizzly.CommandClass.NodeProvisioning.Get,
          Grizzly.CommandClass.NodeProvisioning.Set,
          Grizzly.CommandClass.NodeProvisioning.ListAll,
          Grizzly.CommandClass.NodeProvisioning.ListIterationGet,
          Grizzly.CommandClass.NodeProvisioning.Delete,
          Grizzly.CommandClass.Powerlevel.Get,
          Grizzly.CommandClass.Powerlevel.Set,
          Grizzly.CommandClass.Powerlevel.TestNodeGet,
          Grizzly.CommandClass.Powerlevel.TestNodeSet,
          Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingGet,
          Grizzly.CommandClass.ScheduleEntryLock.DailyRepeatingSet,
          Grizzly.CommandClass.ScheduleEntryLock.EnableAllSet,
          Grizzly.CommandClass.ScheduleEntryLock.EnableSet,
          Grizzly.CommandClass.ScheduleEntryLock.SupportedGet,
          Grizzly.CommandClass.ScheduleEntryLock.YearDayGet,
          Grizzly.CommandClass.ScheduleEntryLock.YearDaySet,
          Grizzly.CommandClass.SensorMultilevel.Get,
          Grizzly.CommandClass.SensorMultilevel.SupportedGetSensor,
          Grizzly.CommandClass.SwitchBinary.Get,
          Grizzly.CommandClass.SwitchBinary.Set,
          Grizzly.CommandClass.SwitchMultilevel.Get,
          Grizzly.CommandClass.SwitchMultilevel.Set,
          Grizzly.CommandClass.ThermostatFanMode.Get,
          Grizzly.CommandClass.ThermostatFanMode.Set,
          Grizzly.CommandClass.ThermostatFanState.Get,
          Grizzly.CommandClass.ThermostatMode.Get,
          Grizzly.CommandClass.ThermostatMode.Set,
          Grizzly.CommandClass.ThermostatSetback.Get,
          Grizzly.CommandClass.ThermostatSetback.Set,
          Grizzly.CommandClass.ThermostatSetpoint.Get,
          Grizzly.CommandClass.ThermostatSetpoint.Set,
          Grizzly.CommandClass.Time.DateGet,
          Grizzly.CommandClass.Time.OffsetGet,
          Grizzly.CommandClass.Time.OffsetSet,
          Grizzly.CommandClass.Time.TimeGet,
          Grizzly.CommandClass.TimeParameters.Get,
          Grizzly.CommandClass.TimeParameters.Set,
          Grizzly.CommandClass.UserCode.Get,
          Grizzly.CommandClass.UserCode.Set,
          Grizzly.CommandClass.UserCode.UsersNumberGet,
          Grizzly.CommandClass.Version.CommandClassGet,
          Grizzly.CommandClass.Version.Get,
          Grizzly.CommandClass.WakeUp.IntervalCapabilitiesGet,
          Grizzly.CommandClass.WakeUp.IntervalGet,
          Grizzly.CommandClass.WakeUp.IntervalSet,
          Grizzly.CommandClass.WakeUp.NoMoreInformation,
          Grizzly.CommandClass.ZipNd.InvNodeSolicitation,
          Grizzly.CommandClass.ZwaveplusInfo.Get
        ]
      ]
    ]
  end
end
