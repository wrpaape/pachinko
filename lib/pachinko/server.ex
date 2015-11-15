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

  defp generate_buckets(max_pos) do
    max_pos
    |> Pachinko.stagger_slots
    |> Enum.map(&{&1, 0})
    |> Enum.into(%{})
  end

  defp generate_balls(num_balls), do: List.duplicate(num_balls, 0)

  defp append_new_ball(live_balls), do: live_balls ++ [0]

  def drop({[dead_ball, live_balls], buckets}) do
    receive do
      {printer_pid, :update_state} ->
        shifted_balls =
          live_balls
          |> append_new_ball
          |> shift

        updated_buckets =
          buckets
          |> Map.update!(dead_ball, &(&1 + 1))

        next_state = {shifted_balls, updated_buckets}

        send(printer_pid, {:next_state, next_state})

        drop(next_state)
    end
  end

  def drop([], state), do: drop(state)
  def drop([live_ball, dead_balls], {live_balls, buckets}) do
    receive do
      {printer_pid, :update_state} ->
        shifted_balls =
          [live_ball | live_balls]
          |> shift

        next_state = {shifted_balls, buckets}

        send(printer_pid, {:next_state, next_state})

        drop(dead_balls, next_state)
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
end