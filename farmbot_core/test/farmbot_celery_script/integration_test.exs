# This is a "kitch sink" of sorts.
defmodule FarmbotCeleryScript.IntegrationTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.Compiler
  alias FarmbotCeleryScript.AST

  @fixtures [
    "fixture/inner_sequence.json",
    "fixture/master_sequence.json",
    "fixture/outer_sequence.json",
    "fixture/paramater_sequence.json",
    "fixture/point_group_sequence.json",
    "fixture/unbound.json",
    "test/fixtures/mark_variable_meta.json",
    "test/fixtures/mark_variable_removed.json",
    "test/fixtures/set_mounted_tool_id.json",
    "test/fixtures/update_resource_multi.json"
    # "fixture/sequence_pair.json",
    # "fixture/unbound_var_x.json",
  ]

  test "all the fixtures (should not crash!)" do
    Enum.map(@fixtures, &compile_celery_file/1)
  end

  def compile_celery_file(json_path) do
    ast =
      json_path
      |> File.read!()
      |> Jason.decode!()
      |> AST.decode()

    Compiler.compile(ast, %{})
  end
end
