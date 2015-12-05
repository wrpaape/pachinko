defmodule Pachinko.Server.Generate do
  alias Pachinko.Fetch

  @p Fetch.pr_shift_right!

  @moduledoc """
  Module responsible for generating initial state for Server process.
  """

  def balls(num_balls) do
    [0, nil]
    |> Enum.map(&List.duplicate(&1, num_balls))
    |> List.to_tuple
    |> Tuple.append(nil)
  end

  def bins(n) do
    fact_map =
      Stream.unfold({0, 1}, fn(current = {i, fact}) ->
        next_i = i + 1

        {current, {next_i, fact * next_i}}
      end)
      |> Enum.take(n + 1)
      |> Enum.into(Map.new)

    pr_k = fn(k) ->
      n_minus_k = n - k
      
      :math.pow(@p, k) * :math.pow(1 - @p, n_minus_k) * fact_map[n] / (fact_map[k] * fact_map[n_minus_k])
    end

    initial_counts =
      n
      |> Pachinko.reflect_stagger
      |> Enum.with_index
      |> Enum.map(fn({bin_pos, k}) ->
        {bin_pos, { pr_k.(k), {0, 0, 0} } }
      end)
      
    Map.new
    |> Map.put(:counts, initial_counts)
    |> Map.put(:total_count, 0)
    |> Map.put(:max_full_blocks, 0)
    |> Map.put(:degrees_of_freedom, n)
    |> Map.put(:chi_squared, "N/A")
    |> Map.put(:p_value, "N/A")
  end
end