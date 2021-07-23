defmodule FarmbotCeleryScript do
  @moduledoc """
  Operations for Farmbot's internal scripting language.
  """

  alias FarmbotCeleryScript.{AST, StepRunner, Scheduler}
  require FarmbotCore.Logger

  @doc "Schedule an AST to execute on a DateTime"
  def schedule(%AST{} = ast, %DateTime{} = at, %{} = data) do
    Scheduler.schedule(ast, at, data)
  end

  @error_message "Unexpected entrypoint: "
  @entrypoints [
    :execute,
    :sequence,
    :rpc_request,
    "execute",
    "sequence",
    "rpc_request",
  ]

  @doc "Execute an AST in place"
  def execute(%AST{} = ast, tag, caller \\ self()) do
    kind = ast.kind
    if kind in @entrypoints do
      StepRunner.begin(caller, tag, ast)
    else
      msg = @error_message <> inspect(kind)
      FarmbotCore.Logger.error(3, msg)
      raise msg
    end
  end
end
