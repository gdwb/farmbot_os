defmodule FarmbotCeleryScript.Compiler.Utils do
  @doc """
  Recursively compiles a list or single Celery AST into an Elixir `__block__`
  """
  def compile_block(_asts, _cs_scope) do
    raise "I need to re-incorporate cs_scope. Probbly with recursion."
  end

  def decompose_block_to_steps({:__block__, steps} = _orig) do
    Enum.map(steps, fn step ->
      quote location: :keep do
        fn -> unquote(step) end
      end
    end)
  end

  def add_sequence_init_and_complete_logs(steps, sequence_name)
      when is_binary(sequence_name) do
    # This looks really weird because of the logs before and
    # after the compiled steps
    List.flatten([
      quote do
        fn ->
          FarmbotCeleryScript.SysCalls.sequence_init_log(
            "Starting #{unquote(sequence_name)}"
          )
        end
      end,
      steps,
      quote do
        fn ->
          FarmbotCeleryScript.SysCalls.sequence_complete_log(
            "Completed #{unquote(sequence_name)}"
          )
        end
      end
    ])
  end

  def add_sequence_init_and_complete_logs(steps, _) do
    steps
  end

  def add_sequence_init_and_complete_logs_ittr(steps, sequence_name)
      when is_binary(sequence_name) do
    # This looks really weird because of the logs before and
    # after the compiled steps
    List.flatten([
      quote do
        fn _ ->
          [
            fn ->
              FarmbotCeleryScript.SysCalls.sequence_init_log(
                "Starting #{unquote(sequence_name)}"
              )
            end
          ]
        end
      end,
      steps,
      quote do
        fn _ ->
          [
            fn ->
              FarmbotCeleryScript.SysCalls.sequence_complete_log(
                "Completed #{unquote(sequence_name)}"
              )
            end
          ]
        end
      end
    ])
  end

  def add_sequence_init_and_complete_logs_ittr(steps, _) do
    steps
  end
end
