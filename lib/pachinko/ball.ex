defmodule Pachinko.Ball do
  @moduledoc """
  
  """
  def gnerate_balls(num_balls) do
    List.duplicate({0, 0}, num_balls)
    |> wait_for_drop
  end

  defp drop(balls) do
    receive 1111
      {:drop} ->
    end
  end
end