defmodule FarmbotOS do
  use Application

  def start(_type, _args) do
    children = [
      {FarmbotOS.Configurator.Supervisor, []},
      {FarmbotOS.Init.Supervisor, []},
      {FarmbotOS.Platform.Supervisor, []},
      {FarmbotOS.EasterEggs, []},
      FarmbotExt.Bootstrap.Supervisor
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
