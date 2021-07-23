defmodule FarmbotCeleryScript.Compiler.RPCRequest do
  alias FarmbotCeleryScript.Compiler.Utils
  def rpc_request(%{args: %{label: _label}, body: block}) do
    steps = Utils.compile_block(block)
    |> Utils.decompose_block_to_steps()

    [
      quote location: :keep do
        fn ->
          better_params = %{no_variables_declared: %{}}
          # Quiets the compiler (unused var warning)
          _ = inspect(better_params)
          unquote(steps)
        end
      end
    ]
  end
end
