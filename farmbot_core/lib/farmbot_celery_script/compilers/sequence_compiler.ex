defmodule FarmbotCeleryScript.Compiler.Sequence do
  alias FarmbotCeleryScript.Compiler.Utils

  def sequence(%{args: %{locals: %{body: params_or_iterables}}} = ast) do
    # if there is an iterable AST here,
    # we need to compile _many_ sequences, not just one.

    iterable_ast = FarmbotCeleryScript
    .Compiler
    .ParameterSupport
    .extract_iterable(params_or_iterables)

    if iterable_ast do
      compile_sequence_iterable(iterable_ast, ast)
    else
      compile_sequence(ast)
    end
  end

  def compile_sequence_iterable(
        iterable_ast,
        %{
          args: %{locals: %{body: _} = locals} = sequence_args,
          meta: sequence_meta
        } = sequence_ast) do
    sequence_name =
      sequence_meta[:sequence_name] || sequence_args[:sequence_name]

    # will be a point_group or every_point node
    group_ast = iterable_ast.args.data_value
    # check if it's a point_group first, then fall back to every_point
    point_group_arg =
      group_ast.args[:point_group_id] || group_ast.args[:resource_id]

    # lookup all point_groups related to this value
    case FarmbotCeleryScript.SysCalls.find_points_via_group(point_group_arg) do
      {:error, reason} ->
        quote location: :keep, do: Macro.escape({:error, unquote(reason)})

      %{name: group_name} = point_group ->
        total = Enum.count(point_group.point_ids)
        # Map over all the points returned by `find_points_via_group/1`
        {body, _} =
          Enum.reduce(point_group.point_ids, {[], 1}, fn point_id,
                                                         {acc, index} ->
            parameter_application = %FarmbotCeleryScript.AST{
              kind: :parameter_application,
              args: %{
                # inject the replacement with the same label
                label: iterable_ast.args.label,
                data_value: %FarmbotCeleryScript.AST{
                  kind: :point,
                  args: %{pointer_type: "GenericPointer", pointer_id: point_id}
                }
              }
            }

            sequence_name =
              case FarmbotCeleryScript.SysCalls.point(
                     "GenericPointer",
                     point_id
                   ) do
                %{name: name, x: x, y: y, z: z} when is_binary(sequence_name) ->
                  pos = FarmbotCeleryScript.FormatUtil.format_coord(x, y, z)
                  sequence_name <> " [#{index} / #{total}] - #{name} #{pos}"

                %{name: name, x: x, y: y, z: z} ->
                  pos = FarmbotCeleryScript.FormatUtil.format_coord(x, y, z)

                  "unnamed iterable sequence [#{index} / #{total}] - #{name} #{
                    pos
                  }"

                _ ->
                  "unknown iterable [#{index} / #{total}]"
              end

            # compile a `sequence` ast, injecting the appropriate `point` ast with
            # the matching `label`
            # TODO(Connor) - the body of this ast should have the
            # params as sorted earlier. Figure out why this doesn't work
            body =
              compile_sequence(
                %{
                  sequence_ast
                  | meta: %{sequence_name: sequence_name},
                    args: %{locals: %{locals | body: [parameter_application]}}
                })

            {acc ++ body, index + 1}
          end)

          Utils.add_sequence_init_and_complete_logs(
          body,
          sequence_name <> " - #{group_name} (#{total} items)"
        )
    end
  end

  def create_better_params(body) do
    IO.inspect(body, label: "=== TODO: create_better_params")
    %{unfinished: "YES"}
  end

  def compile_sequence(%{args: %{locals: %{body: params}} = args, body: block, meta: meta}) do
    sequence_name = meta[:sequence_name] || args[:sequence_name]
    steps = Utils.compile_block(block) |> Utils.decompose_block_to_steps()
    steps = Utils.add_sequence_init_and_complete_logs(steps, sequence_name)

    better_params = create_better_params(params)

    [
      quote location: :keep do
        fn params ->
          # This quiets a compiler warning if there are no variables in this block
          _ = inspect(params)
          better_params = unquote(better_params)
          _ = inspect(better_params)
          # Unquote the remaining sequence steps.
          unquote(steps)
        end
      end
    ]
  end
end
