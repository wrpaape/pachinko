defmodule Pachinko.Server do
  use GenServer

  @moduledoc """
  Module housing the processes that track the state of the balls
  and bucket counts
  """

  # External API

  def start_link(max_ball_spread) do
    {:ok, _server_pid} =
    __MODULE__
    |> GenServer.start_link([max_ball_spread], name: __MODULE__)
  end

  def update_state do
    __MODULE__
    |> GenServer.call(:update_state)
  end

  # GenServer implementation

  def init(max_ball_spread) do
    empty_buckets =
      max_ball_spread
      |> Pachinko.generate_slots(Tuple.duplicate(0, 3))

    dead_balls =
      max_ball_spread + 1
      |> generate_balls

    initial_state =
      {dead_balls, [], buckets}

    {:ok, initial_state}
  end

  def handle_cast({:ready, initial_state}, _from) do
    {:update_state, ^printer_pid} =
    __MODULE__
    |> GenServer.call(:drop)
  end

  def handle_call(:drop, _from, current_value) do

  end

  defp generate_balls(num_balls), do: List.duplicate(0, num_balls)

  def drop(live_balls, buckets}) do
    receive do
      {^printer_pid, :update_state} ->
        {live_balls, [dead_ball]} =
          live_balls
          |> Enum.split(-1)

        next_balls =
          [0 | shift(live_balls)]

        next_buckets =
          buckets
          |> Map.update!(dead_ball, fn({count, full_blocks, remainder}) ->
            case remainder do
              7 -> {count + 1, full_blocks + 1, 0}
              _ -> {count + 1, full_blocks, remainder + 1}
            end
          end)

        send(printer_pid, {:next_state, next_balls, next_buckets})

        drop(next_balls, next_buckets)
    end
  end

  def drop([], live_balls, buckets), do: drop(live_balls, buckets)
  def drop([live_ball | dead_balls], live_balls, buckets) do
    receive do
      {^printer_pid, :update_state} ->
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