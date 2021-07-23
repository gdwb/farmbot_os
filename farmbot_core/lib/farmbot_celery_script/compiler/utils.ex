defmodule FarmbotCeleryScript.Compiler.Utils do
  alias FarmbotCeleryScript.{
    AST,
    Compiler,
    Compiler.IdentifierSanitizer
  }

  @doc """
  Recursively compiles a list or single Celery AST into an Elixir `__block__`
  """
  def compile_block(asts, acc \\ [])

  def compile_block(%AST{} = ast,  _) do
    compiled = ast
    |> Compiler.compile_ast_to_fun()
    |> List.wrap()
    {:__block__, compiled}
  end

  def compile_block([ast | rest],  acc) do
    output = Compiler.compile_ast_to_fun(ast)

    case output do
      compiled when is_list(compiled) ->
        compile_block(rest,  acc ++ compiled)
      compiled ->
          compile_block(rest,  acc ++ [compiled])
    end
  end

  def compile_block([],  acc), do: {:__block__,  acc}

  @doc """
  Compiles a `execute` block to a parameter block

  # Example
  The body of this `execute` node

      {
        "kind": "execute",
        "args": {
          "sequence_id": 123
        },
        "body": [
          {
            "kind": "variable_declaration",
            "args": {
              "label": "variable_in_this_scope",
              "data_value": {
                "kind": "identifier",
                "args": {
                  "label": "variable_in_next_scope"
                }
              }
            }
          }
        ]
      }

  Would be compiled to:

      [variable_in_next_scope: variable_in_this_scope]
  """
  def compile_params_to_function_args(list,  acc \\ [])

  def compile_params_to_function_args([%{kind: :parameter_application, args: args} | rest], acc) do
    %{
      label: next_scope_var_name,
      data_value: data_value
    } = args

    next_scope_var_name = IdentifierSanitizer.to_variable(next_scope_var_name)
    # next_value = Compiler.compile_ast_to_fun(data_value)

    var =
      quote location: :keep do
        {unquote(next_scope_var_name),
         unquote(Compiler.compile_ast_to_fun(data_value))}
      end

    compile_params_to_function_args(rest,  [var | acc])
  end

  def compile_params_to_function_args([], acc), do: acc

  @doc """
  Compiles a function block's params.

  # Example
  A `sequence`s `locals` that look like
      {
        "kind": "scope_declaration",
        "args": {},
        "body": [
          {
            "kind": "parameter_declaration",
            "args": {
              "label": "parent",
              "default_value": {
                "kind": "coordinate",
                "args": {
                  "x": 100.0,
                  "y": 200.0,
                  "z": 300.0
                }
            }
          }
        ]
      }

  Would be compiled to

      parent = Keyword.get(params, :parent, %{x: 100, y: 200, z: 300})
  """
  def compile_param_declaration(%{args: %{label: var_name, default_value: default}}) do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name,  __MODULE__}) =
        Keyword.get(
          params,
          unquote(var_name),
          unquote(Compiler.compile_ast_to_fun(default))
        )

      _ = unquote({var_name,  __MODULE__})
    end
  end

  @doc """
  Compiles a function block's assigned value.

  # Example
  A `sequence`s `locals` that look like
      {
        "kind": "scope_declaration",
        "args": {},
        "body": [
          {
            "kind": "parameter_application",
            "args": {
              "label": "parent",
              "data_value": {
                "kind": "coordinate",
                "args": {
                  "x": 100.0,
                  "y": 200.0,
                  "z": 300.0
                }
              }
            }
          }
        ]
      }
  """
  def compile_param_application(%{args: %{label: var_name, data_value: value}}) do
    var_name = IdentifierSanitizer.to_variable(var_name)

    quote location: :keep do
      unquote({var_name, [], __MODULE__}) =
        unquote(Compiler.compile_ast_to_fun(value))
    end
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
