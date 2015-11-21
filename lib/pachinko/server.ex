defmodule Pachinko.Server do
  @p 0.5 #coinflip

  use GenServer

  @moduledoc """
  Module housing the processes that track the state of the balls
  and bin counts
  """

  ########################################################################
  #                             external API                             #
  ########################################################################

  def start_link(max_ball_spread) do
    {:ok, _server_pid} =
    __MODULE__
    |> GenServer.start_link(max_ball_spread, name: __MODULE__)
  end

  def state, do: __MODULE__ |> GenServer.call(:state)

  def update, do: __MODULE__ |> GenServer.cast(:update)

  def restart, do: __MODULE__ |> GenServer.cast(:exit)

  ########################################################################
  #                       GenServer implementation                       #
  ########################################################################

  def handle_cast(:exit, final_state), do: exit(:normal)

  def init(max_ball_spread) do
    empty_bins =
      max_ball_spread
      |> generate_bins

    dead_and_nil_balls =
      max_ball_spread
      |> + 1
      |> generate_balls

    initial_state =
      dead_and_nil_balls
      |> Tuple.append(empty_bins)

    {:ok, initial_state}
  end

  # all balls are live
  # one ball drops into a bin (dead) and is replaced by a new ball
  def handle_cast(:update, {live_balls, _last_bin_ball, bins}) do
    {live_balls, [bin_ball]} =
      live_balls
      |> Enum.split(-1)

    next_balls =
      [0 | shift(live_balls)]

    next_bins =
      bins
      |> update_bins(bin_ball)
      
    { :noreply, {next_balls, bin_ball, next_bins} }
  end

  # last of dead balls are dropped, the empty list will be dropped
  # :update is casted again to retreive a reply with next_state
  def handle_cast(:update, {[], live_balls, nil, bins}) do
    handle_cast(:update, {live_balls, nil, bins})
  end

  # balls are dropped into play one at a time
  # bins are still out of reach
  def handle_cast(:update, {[live_ball | dead_balls], live_and_nil_balls, nil, bins}) do
    {live_balls, nil_balls} =
      live_and_nil_balls
      |> Enum.split_while(& &1)

    next_balls =
      [live_ball | shift(live_balls) ++ Enum.drop(nil_balls, 1)]

    { :noreply, {dead_balls, next_balls, nil, bins} }
  end

  def handle_call(:state, _from, state), do: reply_state(state)

  ######################################################################
  #                          private helpers                           #
  ######################################################################

  defp update_bins(bins, bin_ball) do
    { pr_bin, {actual_count, full_blocks, remainder} } =
      bins.counts[bin_ball]

    actual_count = actual_count + 1
    remainder = remainder + 1

    if remainder == 8 do
      remainder = 0
      full_blocks = full_blocks + 1
      if full_blocks > bins.max_full_blocks do
        bins =
          bins
          |> Map.put(:max_full_blocks, full_blocks)
      end
    end

    bins.counts[bin_ball]
    |> put_in({ pr_bin, {actual_count, full_blocks, remainder} })
    |> Map.update!(:total_count, &(&1 + 1))
    |> update_chi_squared
  end

  defp update_chi_squared(%{counts: counts, total_count: total_count} = bins) do
    chi_squared =
      counts
      |> Enum.reduce(0, fn({ pr_bin, {actual_count, _full_blocks, _remainder} }, acc) ->
        bin_term =
          actual_count / total_count
          |> - pr_bin
          |> :math.pow(2)

        acc + bin_term / pr_bin
      end) * total_count

    bins
    |> Map.put(:chi_squared, chi_squared)
  end

  # do not include dead_balls in reply
  defp reply_state(state = {_live_balls, _bin_ball, _bins}) do 
    {:reply, state |> format_reply, state}
  end

  defp reply_state(drop_state) do 
    {:reply, drop_state |> Tuple.delete_at(0) |> format_reply, drop_state}
  end

  defp format_reply({live_balls, bin_ball, bins}) do
    {live_balls, bin_ball, bins |> Map.update!(:counts, &Enum.sort/1)}
  end

  defp generate_bins(max_ball_spread) do
    max_ball_spread
    |> Pachinko.reflect_stagger
    |> Enum.with_index
    # |> Enum.map(&{&1, Tuple.duplicate(0, 3)})
    |> Enum.map(fn({bin_pos, index}) ->
      pr_bin =
        :math.pow(@p, index) * :math.pow(@p - 1, max_ball_spread - index)

      {bin_pos, { pr_bin, {0, 0, 0} } }
    end)
    |> Enum.into(Map.new)
    |> List.wrap
    |> List.insert_at(0, :counts)
    |> List.to_tuple
    |> List.wrap
    |> Keyword.put_new(:total_count, 0)
    |> Keyword.put_new(:max_full_blocks, 0)
    |> Keyword.put_new(:chi_squared, 0)
    |> Enum.into(Map.new)
  end

  defp generate_balls(num_balls) do
    [0, nil]
    |> Enum.map(&List.duplicate(&1, num_balls))
    |> List.to_tuple
    |> Tuple.append(nil)
  end

  defp shift(balls) do
    balls
    |> Enum.map(fn(pos) ->
      [-1, 1]
      |> Enum.random
      |> + pos
    end)
  end
end