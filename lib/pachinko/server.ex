defmodule Panchinko.Server do
  @moduledoc """
  Module housing the processes that track the state of the balls
  and bucket counts
  """
  # defp fetch!({:ok, result}), do: result
  # defp fetch_cols, do: :io.columns |> fetch!
  def start do
    # rows = Fetch.dim(:rows)
    # cols        = Fetch.dim(:cols)
    {:ok, cols} = :io.columns
    # num_buckets = cols / 2 |> Float.ceil |> trunc
    num_balls = cols + 1 |> div(2) |> + 1
    initial_state = {[], generate_buckets(num_balls)}

    num_balls
    |> generate_balls
    |> drop(initial_state)
  end

  defp stagger_symmetric(max_pos) do
    -max_pos..max_pos
    |> Enum.take_every(2)
  end

  defp generate_buckets(max_pos) do
    max_pos
    |> stagger_symmetric
    |> Enum.map(&{&1, 0})
    |> Enum.into(%{})
  end

  defp generate_balls(num_balls), do: List.duplicate(num_balls, 0)

  defp drop([], state), do: drop(state)
  defp drop([live_ball, dead_balls], {live_balls, buckets}) do
    receive do
      {:next_state} ->
        shifted_balls = shift([live_ball | live_balls])

        next_state = {shifted_balls, buckets}

        send(Panchinko.Printer, {next_state: next_state})

        drop(dead_balls, next_state)
    end
  end

  defp drop({[dead_ball, live_balls], buckets}) do
    receive do
      {:next_state} ->
        shifted_balls = shift(live_balls ++ [0])
        updated_buckets =
          buckets
          |> Map.update!(dead_ball, &(&1 + 1))

        next_state = {shifted_balls, buckets}

        send(Panchinko.Printer, {next_state: next_state})

        drop(dead_balls, next_state)

        buckets
        |> Map.update!(dead_ball, &(&1 + 1))
        
        drop(live_balls ++ [{0, 0}], buckets)
    end
  end

  defp flip_coin do
    rand = :rand.uniform
    cond do
      rand > 0.5 -> :heads
      rand < 0.5 -> :tails
      true       -> flip_coin
    end
  end

  defp shift(balls) do
    balls
    |> Enum.map(fn(pos) ->
      pos + if flip_coin == :heads, do: 1, else: -1
    end)
  end

  def update({[dead_ball | live_balls], buckets) do

    buckets
    
    |> update(live_balls ++ [{0, 0}])
  end


  def ready(state) do
    receive do
      {:next_state} ->
        send(Panchinko.Printer, state)

        state
        |> update
        |> ready
    end
  end
end