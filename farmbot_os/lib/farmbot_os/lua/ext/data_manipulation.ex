defmodule FarmbotOS.Lua.Ext.DataManipulation do
  @moduledoc """
  Extensions for manipulating data from Lua
  """

  alias FarmbotCore.{Asset, JSON}
  alias FarmbotCore.Asset.{Device, FbosConfig, FirmwareConfig}
  alias FarmbotOS.Lua.Util
  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotExt.HTTP
  alias FarmbotCeleryScript.SpecialValue

  @methods %{
    "connect" => :connect,
    "delete" => :delete,
    "get" => :get,
    "head" => :head,
    "options" => :options,
    "patch" => :patch,
    "post" => :post,
    "put" => :put,
    "trace" => :trace
  }

  def http([lua_config], lua) do
    config = Util.lua_to_elixir(lua_config)
    url = Map.fetch!(config, "url")
    method_str = String.downcase(Map.get(config, "method", "get")) || "get"
    method = Map.get(@methods, method_str, :get)
    headers = Map.to_list(Map.get(config, "headers", %{}))
    body = Map.get(config, "body", "")
    options = []
    hackney = HTTP.hackney()

    # Example request:
    #     {:ok, 200,
    #    [
    #      {"Access-Control-Allow-Origin", "*"},
    #      {"Content-Length", "33"},
    #      {"Content-Type", "application/json; charset=utf-8"},
    #    ], #Reference<0.3657984643.824705025.36946>}
    # }
    {:ok, status, resp_headers, client_ref} =
      hackney.request(method, url, headers, body, options)

    # Example response body: {:ok, "{\"whatever\": \"foo_bar_baz\"}"}
    {:ok, resp_body} = hackney.body(client_ref)
    result = %{body: resp_body, headers: Map.new(resp_headers), status: status}

    {[Util.elixir_to_lua(result)], lua}
  end

  def env([key, value], lua) do
    with :ok <- FarmbotOS.SysCalls.set_user_env(key, value) do
      {[value], lua}
    else
      {:error, reason} ->
        {[nil, reason], lua}

      error ->
        {[nil, inspect(error)], lua}
    end
  end

  def env([key], lua) do
    result =
      Asset.list_farmware_env()
      |> Enum.map(fn e -> {e.key, e.value} end)
      |> Map.new()
      |> Map.get(key)

    {[result], lua}
  end

  def json_encode([data], lua) do
    with {:ok, json} <- JSON.encode(Util.lua_to_elixir(data)) do
      {[json], lua}
    else
      _ -> {[nil, "Error serializing JSON."], lua}
    end
  end

  def json_decode([data], lua) do
    with {:ok, map} <- JSON.decode(data) do
      {[Util.elixir_to_lua(map)], lua}
    else
      _ -> {[nil, "Error parsing JSON."], lua}
    end
  end

  def take_photo(_, lua) do
    case FarmbotOS.SysCalls.Farmware.execute_script("take-photo", %{}) do
      {:error, reason} -> {[reason], lua}
      :ok -> {[], lua}
      other -> {[inspect(other)], lua}
    end
  end

  def update_device([table], lua) do
    params = Map.new(table)
    _ = ResourceUpdate.update_resource("Device", nil, params)
    {[true], lua}
  end

  def get_device([field], lua) do
    device = Asset.device() |> Device.render()
    {[device[String.to_atom(field)]], lua}
  end

  def get_device(_, lua) do
    device = Asset.device() |> Device.render()
    {[Util.elixir_to_lua(device)], lua}
  end

  def update_fbos_config([table], lua) do
    Map.new(table)
    |> Asset.update_fbos_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_fbos_config([field], lua) do
    fbos_config = Asset.fbos_config() |> FbosConfig.render()
    {[fbos_config[String.to_atom(field)]], lua}
  end

  def get_fbos_config(_, lua) do
    conf =
      Asset.fbos_config()
      |> FbosConfig.render()
      |> Util.elixir_to_lua()

    {[conf], lua}
  end

  def update_firmware_config([table], lua) do
    Map.new(table)
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_firmware_config([field], lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[firmware_config[String.to_atom(field)]], lua}
  end

  def get_firmware_config(_, lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[Util.elixir_to_lua(firmware_config)], lua}
  end

  def new_sensor_reading([table], lua) do
    table
    |> Enum.map(fn
      {"mode", val} -> {"mode", round(val)}
      {"pin", val} -> {"pin", round(val)}
      {"value", val} -> {"value", round(val)}
      other -> other
    end)
    |> Map.new()
    |> Asset.new_sensor_reading!()

    {[true], lua}
  end

  def soil_height([x, y], lua),
    do: {[SpecialValue.soil_height(%{x: x, y: y})], lua}
end
