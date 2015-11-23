defmodule Pachinko.Define do
  @moduledoc """
  Defines functions in the calling module.
  """
  defmacro stop_callback(call_back, args \\ []) do
    quote do
      def stop(:pachinko), do: apply(unquote(call_back), unquote(args))
    end
  end
end