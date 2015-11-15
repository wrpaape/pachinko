defmodule Pachinko.Server do
  @moduledoc """
  Module housing the processes that track the state of the balls
  and bucket counts
  """
  def start_link(stash_pid) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, stash_pid, name: __MODULE__)
  end

  def start(max_pos) do
    buckets =
      max_pos
      |> Pachinko.generate_slots(%{count: 0, full_blocks: 0, remainder: 0})

    max_pos + 1
    |> generate_balls
    |> drop([], buckets)
  end


  def generate_balls(num_balls), do: List.duplicate(0, num_balls)

  def inc_with_count(map, other_count) do
    [:count, other_count]
    |> Enum.reduce(map, fn(key, map) ->
      Map.update!(map, key, &(&1 + 1))
    end)
  end

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
          |> Map.update!(dead_ball, fn(bucket) ->
            case bucket.remainder do
              7 ->
                %{bucket | remainder: 0}
                |> inc_with_count(:full_blocks)
              _ ->
                bucket
                |> inc_with_count(:remainder)
            end
          end)

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