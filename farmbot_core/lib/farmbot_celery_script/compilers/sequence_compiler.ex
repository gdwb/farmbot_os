defmodule FarmbotCeleryScript.Compiler.Sequence do
  alias FarmbotCeleryScript.Compiler.{ Scope, Utils }
  def sequence(ast, cs_scope) do
    sequence_header = ast.args.locals.body
    # Apply defaults declared by sequence
    cs_scope
    |> Scope.apply_defaults(sequence_header)
    # Apply declarations within sequence (if any)
    |> Scope.apply_declarations(sequence_header)
    |> Scope.expand()
    |> compile_expanded_sequences(ast)
  end

  defp compile_expanded_sequences(cs_scope_array, ast) do
    IO.inspect(cs_scope_array,loop: "=== SCOPE")
    Enum.map(cs_scope_array, fn cs_scope ->
      steps = ast.body
      |> Utils.compile_block(cs_scope)
      |> Utils.decompose_block_to_steps()
      quote location: :keep do
        fn ->
          better_params = unquote(cs_scope)
          _ = inspect(better_params)
          # Unquote the remaining sequence steps.
          unquote(steps)
        end
      end
    end)
  end
end
