defmodule FarmbotCeleryScript.StepRunner do
  @moduledoc """
  Handles execution of compiled CeleryScript AST
  """
  alias FarmbotCeleryScript.{AST, Compiler}

  @doc """
  Steps through an entire AST.
  """
  def begin(listener, tag, %AST{} = ast) do
    do_step(listener, tag, Compiler.compile(ast))
  end

  def do_step(listener, tag, [fun | rest]) when is_function(fun, 0) do
    case execute(listener, tag, fun) do
      [fun | _] = more when is_function(fun, 0) ->
        do_step(listener, tag, more ++ rest)

      {:error, reason} when is_binary(reason) ->
        send(listener, {:csvm_done, tag, {:error, reason}})
        {:error, reason}

      # Catch non string errors
      {:error, reason} ->
        send(listener, {:csvm_done, tag, {:error, inspect(reason)}})
        {:error, inspect(reason)}

      _ ->
        do_step(listener, tag, rest)
    end
  end

  # def do_step(listener, tag, []) do
  #   send(listener, {:csvm_done, tag, :ok})
  #   :ok
  # end

  defp execute(listener, tag, fun) do
    try do
      fun.()
    rescue
      e ->
        IO.warn("CeleryScript Exception: ", __STACKTRACE__)
        result = {:error, Exception.message(e)}
        send(listener, {:csvm_done, tag, result})
        result
    catch
      _kind, error when is_binary(error) ->
        IO.warn("CeleryScript Error: #{error}", __STACKTRACE__)
        send(listener, {:csvm_done, tag, {:error, error}})
        {:error, error}

      _kind, error ->
        IO.warn("CeleryScript Error: #{inspect(error)}", __STACKTRACE__)
        send(listener, {:csvm_done, tag, {:error, inspect(error)}})
        {:error, inspect(error)}
    end
  end
end
