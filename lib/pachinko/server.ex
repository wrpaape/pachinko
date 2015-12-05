defmodule Pachinko.Server do

  use GenServer

  alias Pachinko.Fetch
  alias Pachinko.Stats
  alias Pachinko.Server.Generate

  @moduledoc """
  Module housing the processes that track the state of the balls
  and bin counts
  """
  @p Fetch.pr_shift_right!


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

  def handle_cast(:exit, _final_state), do: exit(:normal)

  def init(max_ball_spread) do
    empty_bins =
      max_ball_spread
      |> Generate.bins

    dead_and_nil_balls =
      max_ball_spread
      |> + 1
      |> Generate.balls

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
      bins.counts
      |> List.keyfind(bin_ball, 0)
      |> elem(1)

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

    next_tup =
    {bin_ball, { pr_bin, {actual_count, full_blocks, remainder} }}

    bins
    |> Map.update!(:counts, &List.keyreplace(&1, bin_ball, 0, next_tup))
    |> Map.update!(:total_count, &(&1 + 1))
    |> update_stats
  end

  defp update_stats(bins = %{counts: counts, total_count: total_count, degrees_of_freedom: degrees_of_freedom}) do
    chi_squared_norm =
      counts
      |> Enum.reduce(0, fn({ _bin_pos, { pr_bin, {actual_count, _full_blocks, _remainder} } }, acc) ->
        bin_term =
          actual_count / total_count
          |> - pr_bin
          |> :math.pow(2)

        acc + bin_term / pr_bin
      end)
    
    chi_squared = 
      chi_squared_norm * total_count

    bins
    |> Map.put(:chi_squared, chi_squared)
    |> Map.put(:p_value, chi_squared |> Stats.p_value(degrees_of_freedom))
  end

  # do not include dead_balls in reply
  defp reply_state(state = {_live_balls, _bin_ball, _bins}) do 
    {:reply, state, state}
  end

  defp reply_state(drop_state) do 
    {:reply, drop_state |> Tuple.delete_at(0), drop_state}
  end

  # defp format_reply({live_balls, bin_ball, bins}) do
  #   {live_balls, bin_ball, bins |> Map.update!(:counts, &Enum.sort/1)}
  # end

  defp rand_shift do
    rand = :rand.uniform

    cond do
      rand < @p ->  1
      rand > @p -> -1
      true      -> rand_shift
    end
  end

  defp shift(balls) do
    balls
    |> Enum.map(fn(pos) ->
      pos + rand_shift
    end)
  end
end