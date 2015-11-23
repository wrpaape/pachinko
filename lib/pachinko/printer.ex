defmodule Pachinko.Printer do
  use GenServer

  require Integer

  alias Pachinko.Printer.Generate
  alias Pachinko.Server
  alias Pachinko.Fetch
  alias IO.ANSI

  @p                  Fetch.pr_shift_right!
  @int_color_default  ANSI.normal <> ANSI.white
  @int_color_ball     ANSI.bright <> ANSI.yellow

  @moduledoc """
  Prints Pachinko state to stdio.
  """
#   """
#   │●
#   ▁▂▃▄▅▆▇█
#   ●
#      ●    
#     ●.       1|4  ball_pos: -1 , pegs: [0]            slots = %{-1: " ", 1: " "}
#     .●.      2|3  ball_pos:  0 , pegs: [-1, 1]        slots = %{-2: " ", 0: " ", 2: " "}
#    . .●.     3|2  ball_pos:  1 , pegs: [-2, 0, 2]     slots = %{-3: " ", -1: " ", 1: " ", 3: " "}
#   . . . .●   4|1  ball_pos:  4 , pegs: [-3, -1, 1, 3]  
# ├ ┼ ┼●┼ ┼ ┤  cols = 11 / 12
# │0│0│0│0│0│   
# └─┴─┴─┴─┴─┘

  ########################################################################
  #                             external API                             #
  ########################################################################

  def start_link(spread_pad = {_max_ball_spread, _top_pad}) do
    {:ok, _printer_pid} =
      __MODULE__
      |> GenServer.start_link([spread_pad], name: __MODULE__)
  end

  def main([]) do
    Pachinko.ensure_fullscreen
    
    Fetch.frame_interval!
    |> print_frame
  end

  def print_frame(frame_interval) do
    {time_exec, :ready} =
      GenServer
      |> :timer.tc(:call, [__MODULE__, :print_frame])

    frame_interval
    |> - (time_exec / 1000)
    |> trunc
    |> :timer.sleep

    print_frame(frame_interval)
  end

  def state, do: __MODULE__ |> GenServer.call(:state)

  ########################################################################
  #                       GenServer implementation                       #
  ########################################################################

  def init([{max_ball_spread, top_pad}]) do
    y_overflow =
      max_ball_spread
      |> + 1

    peg_rows =
      max_ball_spread
      |> Range.new(0)
      |> Enum.with_index
      |> Enum.map(&Generate.peg_row(&1, y_overflow))

    counter_pieces = 
      max_ball_spread
      |> Generate.counter_pieces

    axis_and_stats =
      max_ball_spread
      |> Generate.axis_and_stats


    initial_state =
      {peg_rows, counter_pieces, axis_and_stats, top_pad, y_overflow}

    {:ok, initial_state}
  end

  def handle_call(:print_frame, _from, printer_state = {_, _, _, _, y_overflow}) do
    # 800~3500 μs (~10_000 max)to process cast
    server_state =
      { _, _, %{max_full_blocks: max_full_blocks} } =
        Server.state

    if max_full_blocks >= y_overflow, do: Server.restart, else: Server.update

    next_frame =       
      server_state
      |> print(printer_state)

    {:reply, :ready, printer_state}  
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  ######################################################################
  #                           public helpers                           #
  ######################################################################

  def print({balls, bin_ball, bins}, {peg_rows, counter_pieces, axis_and_stats, top_pad, _y_overflow}) do
    base =
      counter_pieces
      |> print_base(bin_ball, bins.counts, axis_and_stats, bins)

    main = 
      peg_rows
      |> Enum.zip(balls)
      |> Enum.map_join("\n", &print_row(&1, bins.counts))

    top_pad
    <> main
    <> "\n"
    <> base
    |> IO.puts
  end

  def print_base({mouths_counters, base_counters}, bin_ball, counts, {top_axis, bot_axis, static_stats, print_dynamic_stats}, bins) do
    top =
      mouths_counters
      |> slot_row(bin_ball, "┼")
      |> cap("├", top_axis)

    mid =
      counts
      |> Enum.with_index
      |> Enum.partition(fn({_bin, row_index}) ->
        row_index
        |> Integer.is_odd
      end)
      |> Tuple.to_list      
      |> Enum.map_join(bot_axis, &print_counter_row/1)

     top
     <> mid
     <> static_stats
     <> base_counters
     <> print_dynamic_stats.(bins)
  end

  def print_counter_row(bin_row) do
    bin_row
    |> Enum.map_join(" ", fn({{_bin_pos, { _pr_bin, {actual_count, _full_blocks, _remainder} } }, _row_index}) ->
      actual_count_str = 
      actual_count
      |> Integer.to_string

      case byte_size(actual_count_str) do
        1 -> " " <> actual_count_str <> " "
        2 -> " " <> actual_count_str
        _ ->        actual_count_str
      end
    end)
    |> cap(ANSI.green, ANSI.white)
  end

  def print_row({ { [pad | slots], y_row, row_color }, ball_pos }, counts) do
    pachinko_row =
      slot_row(slots, ball_pos, ".")
      |> cap("╱", "╲")
      |> cap(pad)

    pachinko_row
    <> bell_curve_row(y_row, row_color, counts)
    <> @int_color_default
  end

  def bell_curve_row(y_row, row_color, counts) do
    row =
      counts
      |> Enum.map_join(fn({_pos, { _pr_bin, {_actual_count, full_blocks, remainder} } }) ->
        cond do
          full_blocks < y_row -> "  "
          full_blocks > y_row -> "██"
          remainder  == 0     -> "  "
          true                -> [9600 + remainder] |> List.duplicate(2)
        end
      end)
    
    row_color <> row
  end

  @doc """
  Receives ball_pos and splices a ball token (●)
  into a row of peg tokens (.) before dispatching
  the resulting display string to the print process.

  ## Example
      iex> import Pachinko.Printer, only: [state: 0]
      ...> {[first_row | rest], _} = Pachinko.Printer.state
      ...> pachinko_row({peg_row, nil})
      " . . "

      ...> peg_row = Pachinko.generate_slots(5, " ")
      ...> pachinko_row({peg_row, 1})
      " . . . .●. . " 
  """
  def slot_row(slots, ball_pos, token) do
    slots
    |> Enum.map_join(token, fn(slot_pos) ->
      if slot_pos == ball_pos, do: "☻" |> cap(@int_color_ball, @int_color_default), else: " "
    end)
  end

  def cap(string, lcap, rcap), do: lcap <> string <> rcap
  def cap(string, cap),        do: cap  <> string <> cap
end