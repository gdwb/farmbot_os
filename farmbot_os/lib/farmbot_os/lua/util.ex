defmodule FarmbotOS.Lua.Util do
  @doc "Create a data struture that can be easily passed to the Lua sandbox"
  def elixir_to_lua(list) when is_list(list) do
    list
    |> Enum.with_index(1)
    |> Enum.map(fn {value, index} ->
      {to_string(index), elixir_to_lua(value)}
    end)
  end

  def elixir_to_lua(%DateTime{} = dt), do: to_string(dt)

  def elixir_to_lua(map) when is_map(map) do
    Enum.map(map, fn
      {key, value} -> {to_string(key), elixir_to_lua(value)}
    end)
  end

  def elixir_to_lua(other), do: other

  def lua_to_elixir(table) when is_list(table) do
    table_to_map(table, %{})
  end

  def lua_to_elixir(f) when is_function(f), do: "[Lua Function]"

  def lua_to_elixir(other), do: other

  def table_to_map([{key, value} | rest], acc) do
    next = Map.merge(acc, %{key => lua_to_elixir(value)})
    table_to_map(rest, next)
  end

  def table_to_map([], acc) do
    # POST PROCESSING
    keys = Map.keys(acc)
    not_array? = Enum.find_value(keys, fn key -> !is_number(key) end)
    not_populated? = Enum.count(keys) == 0

    if not_array? || not_populated? do
      acc
    else
      Map.values(acc)
    end
  end
end
