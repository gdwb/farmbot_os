defmodule FarmbotCeleryScript.Compiler.Execute do
  # import FarmbotCeleryScript.Compiler.Utils
  alias FarmbotCeleryScript.Compiler

  # Compiles an `execute` block.
  # This one is actually pretty complex and is split into two parts.
  def execute(%{body: parameter_applications} = ast, cs_scope) do
    # if there is an iterable AST here,
    # we need to compile _many_ sequences, not just one.

    IO.puts("TODO: You need to modify `cs_scope` here!!")
    loop_parameter_appl_ast = FarmbotCeleryScript
      .Compiler
      .ParameterSupport
      .extract_iterable(parameter_applications)

    if loop_parameter_appl_ast,
      do: compile_execute_iterable(ast, cs_scope),
      else: compile_execute(ast, cs_scope)
  end

  def compile_execute_iterable(%{args: %{sequence_id: sequence_id}, body: param_appls}, _cs_scope) do
    quote location: :keep do
      case FarmbotCeleryScript.SysCalls.get_sequence(unquote(sequence_id)) do
        %FarmbotCeleryScript.AST{kind: :sequence} = celery_ast ->
          celery_args =
            celery_ast.args
            |> Map.put(
              :sequence_name,
              celery_ast.args[:name] || celery_ast.meta[:sequence_name]
            )
            |> Map.put(:locals, %{
              celery_ast.args.locals
              | body: celery_ast.args.locals.body ++ unquote(param_appls)
            })

          celery_ast = %{celery_ast | args: celery_args}
          Compiler.compile(celery_ast, cs_scope)

        error ->
          error
      end
    end
  end

  def compile_execute(%{args: %{sequence_id: id}}, cs_scope) do
    quote location: :keep do
      # We have to lookup the sequence by it's id.
      case FarmbotCeleryScript.SysCalls.get_sequence(unquote(id)) do
        %FarmbotCeleryScript.AST{} = ast ->
          FarmbotCeleryScript.Compiler.compile(ast, unquote(cs_scope))
        error ->
          error
      end
    end
  end
end
