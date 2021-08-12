defmodule FarmbotOS.Platform.Host.SystemTasks do
  @moduledoc "Host implementation for Farmbot.System."

  @behaviour FarmbotOS.System

  def reboot() do
    Application.stop(:farmbot)
    Application.stop(:farmbot_core)

    Application.ensure_all_started(:farmbot_core)
    Application.ensure_all_started(:farmbot)
  end

  def shutdown() do
    System.halt()
  end
end
