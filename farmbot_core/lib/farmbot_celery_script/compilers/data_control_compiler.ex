defmodule FarmbotCeleryScript.Compiler.DataControl do
  alias FarmbotCeleryScript.Compiler

  # compiles coordinate
  # Coordinate should return a vec3
  def coordinate(%{args: %{x: x, y: y, z: z}}) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.coordinate(
        unquote(Compiler.compile_ast_to_fun(x)),
        unquote(Compiler.compile_ast_to_fun(y)),
        unquote(Compiler.compile_ast_to_fun(z))
      )
    end
  end

  # compiles point
  def point(%{args: %{pointer_type: type, pointer_id: id}}) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.point(
        unquote(Compiler.compile_ast_to_fun(type)),
        unquote(Compiler.compile_ast_to_fun(id))
      )
    end
  end

  # compile a named pin
  def named_pin(%{args: %{pin_id: id, pin_type: type}}) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.named_pin(
        unquote(Compiler.compile_ast_to_fun(type)),
        unquote(Compiler.compile_ast_to_fun(id))
      )
    end
  end

  def tool(%{args: %{tool_id: tool_id}}) do
    quote location: :keep do
      FarmbotCeleryScript.SysCalls.get_toolslot_for_tool(
        unquote(Compiler.compile_ast_to_fun(tool_id))
      )
    end
  end
end
