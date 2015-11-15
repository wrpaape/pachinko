defmodule Pachinko.Server do
  @moduledoc """
  Module housing the processes that track the state of the balls
  and bucket counts
  """
  # def fetch!({:ok, result}), do: result
  # def fetch_cols, do: :io.columns |> fetch!
  def start do
    # rows = Fetch.dim(:rows)
    # cols        = Fetch.dim(:cols)
    {:ok, cols} = :io.columns
    # num_buckets = cols / 2 |> Float.ceil |> trunc
    max_pos = div(cols + 1, 2)
    max_pos + 1
    |> generate_balls
    |> drop([], generate_buckets(max_pos))
  end

  def generate_buckets(max_pos) do
    max_pos
    |> Pachinko.stagger_slots
    |> Enum.map(&{&1, 0})
    |> Enum.into(%{})
  end

  def generate_balls(num_balls), do: List.duplicate(0, num_balls)

  def append_new_ball(live_balls), do: live_balls ++ [0]

  def drop(live_balls, buckets) do
    receive do
      {printer_pid, :update_state} ->
        {live_balls, [dead_ball]} =
          live_balls
          |> Enum.split(-1)

        next_balls =
          [0 | shift(live_balls)]

        next_buckets =
          buckets
          |> Map.update!(dead_ball, &(&1 + 1))

        send(printer_pid, {:next_state, next_balls, next_buckets})

        drop(next_balls, next_buckets)
    end
  end

  def drop([], live_balls, buckets), do: drop(live_balls, buckets)
  def drop([live_ball | dead_balls], live_balls, buckets) do
    receive do
      {printer_pid, :update_state} ->
        next_balls =
          [live_ball | shift(live_balls)]

        send(printer_pid, {:next_state, next_balls, buckets})

        drop(dead_balls, next_balls, buckets)
    end
  end

  def flip_coin do
    rand = :rand.uniform
    cond do
      rand > 0.5 -> :heads
      rand < 0.5 -> :tails
      true       -> flip_coin
    end
  end

  def shift(balls) do
    balls
    |> Enum.map(fn(pos) ->
      pos + if flip_coin == :heads, do: 1, else: -1
    end)
  end
end