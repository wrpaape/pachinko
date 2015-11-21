defmodule Stats do
  defp fact_stirling(n) do
    :math.pow(2 * :math.pi * n, 0.5) * :math.pow(n / :math.exp(1), n)
  end

  defp gamma_comp(n), do: fact_stirling(n - 1)

  defp gamma_inc(s, x) do
    dt = x / 1000

    0..999
    |> Enum.reduce(fn(i, acc) ->
      t = x * i / 1000

      :math.pow(t, s - 1) * :math.exp(-t) * dt
      |> + acc
    end)
  end

  defp cdf(x, k), do: gamma_inc(k / 2, x / 2) / gamma_comp(k / 2)

  def p_value(x, k) do
    1 - cdf(x, k)
  end
end