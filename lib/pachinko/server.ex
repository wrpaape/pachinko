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
      |> generate_buckets

    dead_and_nil_balls =
      max_ball_spread + 1
      |> generate_balls

    initial_state =
      dead_and_nil_balls
      |> Tuple.append(empty_buckets)

    {:ok, initial_state}
  end

  # all balls are live
  # one ball drops into a bucket (dead) and is replaced by a new ball
  def handle_call(:update, _from, {live_balls, _last_bucket_ball, buckets}) do
    {live_balls, [bucket_ball]} =
      live_balls
      |> Enum.split(-1)

    next_balls =
      [0 | shift(live_balls)]

    next_buckets =
      buckets
      |> update_count(bucket_ball)
      
    {next_balls, bucket_ball, next_buckets}
    |> reply_state   
  end

  # last of dead balls are dropped, the empty list will be dropped
  # :update is called again to retreive a reply with next_state
  def handle_call(:update, from, {[], live_balls, nil, buckets}) do
    handle_call(:update, from, {live_balls, nil, buckets})
  end

  # balls are dropped into play one at a time
  # buckets are still out of reach
  def handle_call(:update, _from, {[live_ball | dead_balls], live_and_nil_balls, nil, buckets}) do
    {live_balls, nil_balls} =
      live_and_nil_balls
      |> Enum.split_while(& &1)

    next_balls =
      [live_ball | shift(live_balls) ++ Enum.drop(nil_balls, 1)]

    {dead_balls, next_balls, nil, buckets}
    |> reply_state
  end

  def handle_call(:state, _from, state), do: reply_state(state)

  ######################################################################
  #                          private helpers                           #
  ######################################################################

  defp update_count(buckets, bucket_ball) do
    buckets
    |> Enum.map(fn(row) ->
      row
      |> Map.update!(bucket_ball, fn({count, full_blocks, remainder}) ->
        case remainder do
          7 -> {count + 1, full_blocks + 1, 0}
          _ -> {count + 1, full_blocks, remainder + 1}
        end
      end)
    end)
  end

  defp call(msg) do
    __MODULE__
    |> GenServer.call(msg)
  end

  # do not include dead_balls in reply
  defp reply_state(state = {_live_balls, _bucket_ball, _buckets}) do 
    {:reply, state |> format, state}
  end

  defp reply_state(drop_state) do 
    {:reply, drop_state |> Tuple.delete_at(0) |> format, drop_state}
  end

  # send buckets as two rows of sorted keyword lists
  defp format({live_balls, bucket_ball, buckets}) do
    {live_balls, bucket_ball, buckets |> Enum.map(&Enum.sort/1)}
  end

  defp generate_buckets(max_ball_spread) do
    all_buckets = 
      max_ball_spread
      |> Pachinko.reflect_stagger
      |> Enum.map(&{&1, Tuple.duplicate(0, 3)})

    top_row =
      all_buckets
      |> tl
      |> Enum

    [all_buckets, tl(all_buckets)]
    |> Enum.map(fn(buckets) ->
      buckets
      |> Enum.take_every(2)
      |> Enum.into(%{})
    end)
  end

  defp generate_balls(num_balls) do
    [0, nil]
    |> Enum.map(&List.duplicate(&1, num_balls))
    |> List.to_tuple
    |> Tuple.append(nil)
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