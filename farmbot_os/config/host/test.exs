use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot, data_path: data_path

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot,
  ecto_repos: [
    FarmbotCore.Config.Repo,
    FarmbotCore.Logger.Repo,
    FarmbotCore.Asset.Repo
  ],
  platform_children: [
    {Farmbot.Platform.Host.Configurator, []}
  ]

config :farmbot, FarmbotOS.Configurator,
  data_layer: FarmbotOS.Configurator.ConfigDataLayer,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :plug, :validate_header_keys_during_test, true

config :ex_unit, capture_logs: true
