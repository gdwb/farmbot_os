Application.ensure_all_started(:mimic)
# Use this to stub out calls to `state.reset.reset()` in firmware.
defmodule StubReset do
  def reset(), do: :ok
end

defmodule NoOp do
  use GenServer

  def new(opts \\ []) do
    {:ok, pid} = start_link(opts)
    pid
  end

  def stop(pid) do
    _ = Process.unlink(pid)
    :ok = GenServer.stop(pid, :normal, 3_000)
  end

  def last_message(pid) do
    :sys.get_state(pid)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, :no_message_yet}
  end

  def handle_info(next_message, _last_message) do
    {:noreply, next_message}
  end
end

defmodule SimpleCounter do
  def new(starting_value \\ 0) do
    Agent.start_link(fn -> starting_value end)
  end

  def get_count(pid) do
    Agent.get(pid, fn count -> count end)
  end

  def incr(pid, by \\ 1) do
    Agent.update(pid, fn count -> count + by end)
    pid
  end

  # Increment the counter by one and get the current count.
  def bump(pid, by \\ 1) do
    pid |> incr(by) |> get_count()
  end
end

[
  Ecto.Changeset,
  ExTTY,
  FarmbotCeleryScript.SpecialValue,
  FarmbotCeleryScript.SysCalls,
  FarmbotCeleryScript.SysCalls.Stubs,
  FarmbotCore.Asset,
  FarmbotCore.Asset.Command,
  FarmbotCore.Asset.Device,
  FarmbotCore.Asset.FbosConfig,
  FarmbotCore.Asset.FirmwareConfig,
  FarmbotCore.Asset.Private,
  FarmbotCore.Asset.Repo,
  FarmbotCore.BotState,
  FarmbotCore.BotStateNG,
  FarmbotCore.Config,
  FarmbotCore.FarmwareRuntime,
  FarmbotCore.Firmware.Command,
  FarmbotCore.Leds,
  FarmbotCore.LogExecutor,
  FarmbotCore.Logger,
  FarmbotExt.API,
  FarmbotExt.API.EagerLoader,
  FarmbotExt.API.EagerLoader.Supervisor,
  FarmbotExt.API.Preloader,
  FarmbotExt.API.Reconciler,
  FarmbotExt.API.SyncGroup,
  FarmbotExt.APIFetcher,
  FarmbotExt.Bootstrap.Authorization,
  FarmbotExt.Bootstrap.DropPasswordSupport,
  FarmbotExt.HTTP,
  FarmbotExt.MQTT,
  FarmbotExt.MQTT.LogHandlerSupport,
  FarmbotExt.MQTT.Support,
  FarmbotExt.MQTT.SyncHandlerSupport,
  FarmbotExt.MQTT.TerminalHandlerSupport,
  FarmbotExt.Time,
  FarmbotOS.Configurator.ConfigDataLayer,
  FarmbotOS.Configurator.DetsTelemetryLayer,
  FarmbotOS.Configurator.FakeNetworkLayer,
  FarmbotOS.Lua.Ext.DataManipulation,
  FarmbotOS.Lua.Ext.Firmware,
  FarmbotOS.Lua.Ext.Info,
  FarmbotOS.SysCalls,
  FarmbotOS.SysCalls.ChangeOwnership.Support,
  FarmbotOS.SysCalls.Farmware,
  FarmbotOS.SysCalls.Movement,
  FarmbotOS.SysCalls.ResourceUpdate,
  FarmbotOS.UpdateSupport,
  FarmbotTelemetry,
  File,
  MuonTrap,
  System,
  Tortoise
]
|> Enum.map(&Mimic.copy/1)

ExUnit.configure(max_cases: 1)
ExUnit.start()
