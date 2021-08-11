use Mix.Config

repos = [
  FarmbotCore.Config.Repo,
  FarmbotCore.Logger.Repo,
  FarmbotCore.Asset.Repo
]

rollbar_token = System.get_env("ROLLBAR_TOKEN")
is_test? = Mix.env() == :test

config :ecto, json_library: FarmbotCore.JSON

config :farmbot_core,
  ecto_repos: [
    FarmbotCore.Config.Repo,
    FarmbotCore.Logger.Repo,
    FarmbotCore.Asset.Repo
  ]

config :farmbot_core, ecto_repos: repos

config :farmbot_core,
       Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
       ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot_core, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotOS.SysCalls

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "asset.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/asset"

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot_core, FarmbotCore.BotState.FileSystem,
  root_dir: "/tmp/farmbot_state"

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "config.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/config"

config :farmbot_core, FarmbotCore.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: FarmbotCore.Core.CeleryScript.StubIOLayer

config :farmbot_core, FarmbotCore.EctoMigrator,
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_dns_name: "my.farm.bot"

config :farmbot_core, FarmbotCore.JSON,
  json_parser: FarmbotCore.JSON.JasonParser

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "logger.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/logger"

config :farmbot, FarmbotExt.API.Preloader,
  preloader_impl: FarmbotExt.API.Preloader.HTTP

config :farmbot, FarmbotExt.Time, disable_timeouts: is_test?

config :farmbot, FarmbotOS.Configurator,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :farmbot, FarmbotOS.FileSystem, data_path: "/tmp/farmbot"

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [FarmbotOS.Platform.Host.Configurator]

config :farmbot, FarmbotOS.System,
  system_tasks: FarmbotOS.Platform.Host.SystemTasks

config :logger, handle_otp_reports: false, handle_sasl_reports: false
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

if rollbar_token && Mix.env() != :test do
  IO.puts("=== ROLLBAR IS ENABLED! ===")

  config :rollbax,
    access_token: rollbar_token,
    environment: "production",
    enable_crash_reports: true,
    custom: %{fbos_version: Mix.Project.config()[:version]}
else
  config :rollbax, enabled: false
end

if Mix.target() == :host do
  if File.exists?("config/host/#{Mix.env()}.exs") do
    import_config("host/#{Mix.env()}.exs")
  end
else
  import_config("target/#{Mix.env()}.exs")

  import_config("target/#{Mix.target()}.exs")
end

if is_test? do
  config :farmbot_os, :reconciler, FarmbotExt.API.TestReconciler
  config :ex_unit, capture_logs: true
  mapper = fn mod -> config :farmbot, mod, children: [] end

  list = [
    FarmbotExt,
    FarmbotExt.MQTT.Supervisor,
    FarmbotExt.MQTT.ChannelSupervisor,
    FarmbotExt.API.DirtyWorker.Supervisor,
    FarmbotExt.API.EagerLoader.Supervisor,
    FarmbotExt.Bootstrap.Supervisor
  ]

  Enum.map(list, mapper)
end
