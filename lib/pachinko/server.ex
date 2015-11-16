defmodule Pachinko.Server do
  use GenServer

  @moduledoc """
  Module housing the processes that track the state of the balls
  and bucket counts
  """

  ########################################################################
  #                             external API                             #
  ########################################################################

  def start_link(max_ball_spread) do
    {:ok, _server_pid} =
    __MODULE__
    |> GenServer.start_link(max_ball_spread, name: __MODULE__)
  end

  def state, do: call(:state)

  def update, do: call(:update)

  ########################################################################
  #                       GenServer implementation                       #
  ########################################################################

  def init(max_ball_spread) do
    empty_buckets =
      max_ball_spread
      |> Pachinko.generate_slots(Tuple.duplicate(0, 3))

    dead_balls =
      max_ball_spread + 1
      |> generate_balls

    initial_state =
      {dead_balls, [], empty_buckets}

    {:ok, initial_state}
  end

  # all balls are live
  # one ball drops into a bucket (dead) and is replaced by a new ball
  def handle_call(:update, _from, {live_balls, buckets}) do
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

    reply_state({next_balls, next_buckets})    
  end

  # last of dead balls are dropped, the empty list will be dropped
  # :update is called again to retreive a reply with next_state
  def handle_call(:update, from, {[], live_balls, buckets}) do
    handle_call(:update, from, {live_balls, buckets})
  end

  # balls are dropped into play one at a time
  # buckets are still out of reach
  def handle_call(:update, _from, {[live_ball | dead_balls], live_balls, buckets}) do
    next_balls =
      [live_ball | shift(live_balls)]

    reply_state({dead_balls, next_balls, buckets})    
  end

  def handle_call(:state, _from, state), do: reply_state(state)

  ######################################################################
  #                          private helpers                           #
  ######################################################################

  defp call(msg) do
    __MODULE__
    |> GenServer.call(msg)
  end

  # do not include dead_balls in reply
  defp reply_state({live_balls, buckets}), do: {:reply, {live_balls, buckets}, {live_balls, buckets}}
  defp reply_state(drop_state),            do: {:reply, Tuple.delete_at(drop_state, 0), drop_state}

  defp generate_balls(num_balls), do: List.duplicate(0, num_balls)

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