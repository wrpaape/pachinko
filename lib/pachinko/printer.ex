defmodule Pachinko.Printer do
  use GenServer

  require Integer

  @int_color_default      IO.ANSI.normal <> IO.ANSI.white
  @int_color_ball         IO.ANSI.bright <> IO.ANSI.yellow

  @moduledoc """
  Prints Pachinko state to stdio.
  """
#   """
#   │●
#   ▁▂▃▄▅▆▇█
#   ●

# [, ,.]
# slots [ , , , ]
# . . . . .
# . . . . .
# ├ ┼─│
# 
#
#      ●    
#     ●.       1|4  ball_pos: -1 , pegs: [0]            slots = %{-1: " ", 1: " "}
#     .●.      2|3  ball_pos:  0 , pegs: [-1, 1]        slots = %{-2: " ", 0: " ", 2: " "}
#    . .●.     3|2  ball_pos:  1 , pegs: [-2, 0, 2]     slots = %{-3: " ", -1: " ", 1: " ", 3: " "}
#   . . . .●   4|1  ball_pos:  4 , pegs: [-3, -1, 1, 3]  
# ├ ┼ ┼●┼ ┼ ┤  cols = 11 / 12
# │0│0│0│0│0│   
# └─┴─┴─┴─┴─┘

# cols        = Fetch.dim(:cols)
# num_buckets = cols / 2 |> Float.ceil |> trunc
# num_rows    = num_buckets - 1
# ball_pos  = 
# len_lpad    = num_rows - row + 1

# slots = num_pegs |> Pachinko.generate_slots(" ")
# slots |>  Map.put(ball_pos, "●") |> Map.values |> Enum.join(".")
#   """

# %{-11 => {0, 0, 0}, -9 => {0, 5, 1}, -7 => {1, 10, 5}, -5 => {3, 12, 7},
#    -3 => {0, 20, 0}, -1 => {5, 30, 5}, 1 => {8, 27, 3}, 3 => {8, 35, 3},
#    5 => {5, 11, 7}, 7 => {1, 1, 1}, 9 => {0, 0, 0}, 11 => {0, 6, 1}}


  ########################################################################
  #                             external API                             #
  ########################################################################

  def start_link(spread_pad = {_max_ball_spread, _top_pad}) do
    {:ok, _printer_pid} =
      __MODULE__
      |> GenServer.start_link([spread_pad], name: __MODULE__)
  end

  def main([]) do
    fetch_frame_interval!
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
    require Integer

    y_overflow =
      max_ball_spread
      |> + 1

    peg_rows =
      max_ball_spread
      |> Range.new(0)
      |> Enum.with_index
      |> Enum.map(&generate_peg_row(&1, y_overflow))

    counter_pieces = 
      max_ball_spread
      |> generate_counter_pieces

    bell_curve_axis =
      max_ball_spread
      |> generate_bell_curve_axis


    initial_state =
      {peg_rows, counter_pieces, bell_curve_axis, top_pad, y_overflow}

    {:ok, initial_state}
  end

  def generate_bell_curve_axis(n) do
    p = 0.5

    std_bucket =
      n * p * (1 - p)
      |> :math.pow(0.5)

    resolution =
      2 * (n + 1)

    std_cols =
      resolution * std_bucket / n

    std_max =
      (resolution - 9) / std_cols
      |> round
      |> div(2)

    {top, bot} =
      1..std_max
      |> Enum.reduce({"", ""}, fn(x, {top_acc, bot_acc}) ->
        len =
          x * std_cols
          |> round
          |> - 1

        { String.ljust(top_acc, len, ?─) <> "┼", String.ljust(bot_acc, len) <> Integer.to_string(x)}
      end)

    bot_pad_len =
      if n |> Integer.is_odd, do: 0, else: 3

    top =
      "┼"
      |> cap(String.reverse(top), top)
      |> cap("σ⁻<─", "─>σ⁺")
      |> cap("┤ ", "\n  ")

    bot =
      "0"
      |> cap(String.reverse(bot), bot)
      |> cap("    ")
      |> cap(String.duplicate(" ", bot_pad_len), "\n")


    {top, bot}
  end

  def handle_call(:print_frame, _from, printer_state = {_, _, _, _, y_overflow}) do
    # 800~3500 μs (~10_000 max)to process cast
    server_state =
      { _, _, %{max_full_blocks: max_full_blocks} } =
        Pachinko.Server.state

    if max_full_blocks >= y_overflow, do: Pachinko.Server.restart, else: Pachinko.Server.update

    next_frame =       
      server_state
      |> print(printer_state)

    {:reply, :ready, printer_state}  
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  ######################################################################
  #                           public helpers                           #
  ######################################################################

  def print({balls, bucket_ball, %{counts_map: counts_map, total_count: total_count}}, {peg_rows, counter_pieces, bell_curve_axis, top_pad, _y_overflow}) do
    base =
      counter_pieces
      |> print_base(bucket_ball, counts_map, bell_curve_axis, total_count)

    main = 
      peg_rows
      |> Enum.zip(balls)
      |> Enum.map_join("\n", &print_row(&1, counts_map))

    top_pad
    <> main
    <> "\n"
    <> base
    |> IO.puts
  end

  def print_base({mouths, base}, bucket_ball, counts_map, {top_axis, bot_axis}, total_count) do
    top =
      mouths
      |> slot_row(bucket_ball, "┼")
      |> cap("├", top_axis)

    mid =
      counts_map
      |> Enum.with_index
      |> Enum.partition(fn({_bucket, row_index}) ->
        row_index
        |> Integer.is_odd
      end)
      |> Tuple.to_list      
      |> Enum.map_join(bot_axis, &print_counter_row/1)
      # <> String.duplicate(" ", 10)
      # <> Integer.to_string(total_count)

     top
     <> mid
     <> "\n"
     <> base
  end

  def print_counter_row(bucket_row) do
    bucket_row
    |> Enum.map_join(" ", fn({{_slot_pos, {count, _full_blocks, _remainder}}, _row_index}) ->
      count_str = 
      count
      |> Integer.to_string

      case byte_size(count_str) do
        1 -> " " <> count_str <> " "
        2 -> " " <> count_str
        _ ->        count_str
      end
    end)
    |> cap(IO.ANSI.green, IO.ANSI.white)
  end

  def print_row({ { [pad | slots], y_row, row_color }, ball_pos }, counts_map) do

    pachinko_row =
      slot_row(slots, ball_pos, ".")
      |> cap("╱", "╲")
      |> cap(pad)

    pachinko_row
    <> bell_curve_row(y_row, row_color, counts_map)
    <> @int_color_default
  end

  def generate_counter_pieces(max_ball_spread) do
    mouths =
      max_ball_spread
      |> Pachinko.reflect_stagger

    base =
      "─"
      |> List.duplicate(max_ball_spread + 1)
      |> Enum.join("┴")

    {mouths, IO.ANSI.white <> cap(base, "└", "┘")}
# ╱
# ├ ┼ ┼●┼ ┼ ┤  cols = 11 / 12
# │0│0│0│0│0│   
# └─┴─┴─┴─┴─┘
  end

  def generate_peg_row({y_row, num_pegs}, y_overflow) do
    pad =
      " "
      |> String.duplicate(y_row)

    slots =
      num_pegs
      |> Pachinko.reflect_stagger

    y_ratio = y_row / y_overflow

    row_color =
      cond do
        y_ratio > 0.85 -> IO.ANSI.bright <> IO.ANSI.magenta
        y_ratio > 0.70 -> IO.ANSI.bright <> IO.ANSI.red
        y_ratio > 0.55 ->                   IO.ANSI.yellow
        y_ratio > 0.40 ->                   IO.ANSI.green  
        y_ratio > 0.20 -> IO.ANSI.faint  <> IO.ANSI.cyan
        true           -> IO.ANSI.faint  <> IO.ANSI.blue
      end

    {[pad | slots], y_row, row_color}
  end

  def bell_curve_row(y_row, row_color, counts_map) do
    row =
      counts_map
      |> Enum.map_join(fn({_pos, {_count, full_blocks, remainder}}) ->
        cond do
          full_blocks < y_row -> " "
          full_blocks > y_row -> "█"
          remainder  == 0     -> " "
          true                -> [9600 + remainder] |> List.to_string
        end
        |> String.duplicate(2)
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

  defp to_whole_microseconds(seconds_per_frame) do
    seconds_per_frame * 1000
    |> Float.ceil
    |> trunc
  end

  defp fetch_frame_interval! do
    :pachinko
    |> Application.get_env(:frame_rate)
    |> :math.pow(-1) 
    |> to_whole_microseconds
  end

  defp cap(string, lcap, rcap), do: lcap <> string <> rcap
  defp cap(string, cap),        do: cap  <> string <> cap
end