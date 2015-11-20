defmodule Pachinko.Printer do
  use GenServer

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
    |> start
  end

  def start(frame_interval) do
    {time_exec, next_frame} =
      GenServer
      |> :timer.tc(:call, [__MODULE__, :next_frame])

    IO.puts next_frame

    frame_interval
    |> - (time_exec / 1000)
    |> trunc
    |> :timer.sleep

    start(frame_interval)
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


    initial_state =
      {peg_rows, counter_pieces, top_pad, y_overflow}

    {:ok, initial_state}
  end

  def handle_call(:next_frame, _from, printer_state = {_, _, _, y_overflow}) do
    # 800~3500 μs (~10_000 max)to process cast
    server_state =
      {_, _, _, max_full_blocks} =
        Pachinko.Server.state

    if max_full_blocks >= y_overflow, do: Pachinko.Server.restart, else: Pachinko.Server.update

    next_frame =       
      server_state
      |> print(printer_state)

    {:reply, next_frame, printer_state}  
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  ######################################################################
  #                           public helpers                           #
  ######################################################################

  def print({balls, bucket_ball, buckets, _max_full_blocks}, {peg_rows, counter_pieces, top_pad, _y_overflow}) do
    counters =
      counter_pieces
      |> print_counters(bucket_ball, buckets)

    main = 
      peg_rows
      |> Enum.zip(balls)
      |> Enum.map_join("\n", &print_row(&1, buckets))

    top_pad <> main <> "\n" <> counters
  end

  def print_counters({mouths, base}, bucket_ball, buckets) do
    require Integer

    printed_top =
      mouths
      |> slot_row(bucket_ball, "┼")

    printed_counts =
      buckets
      |> Enum.with_index
      |> Enum.partition(fn({_bucket, row_index}) ->
        row_index
        |> Integer.is_odd
      end)
      |> Tuple.to_list
      |> Enum.map_join("\n", &print_counter_row/1)

    "├" <> printed_top <> "┤\n  " <> IO.ANSI.green <> printed_counts <>  "\n" <> base
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
  end

  def print_row({ { [pad | slots], y_row, row_color }, ball_pos }, buckets) do
    pad <> "╱" <> slot_row(slots, ball_pos, ".") <> "╲" <> pad <> bell_curve_row(y_row, row_color, buckets) <> IO.ANSI.normal <> IO.ANSI.white
  end

  def generate_counter_pieces(max_ball_spread) do
    mouths =
      max_ball_spread
      |> Pachinko.reflect_stagger

    base =
      "─"
      |> List.duplicate(max_ball_spread + 1)
      |> Enum.join("┴")

    {mouths, IO.ANSI.white <> "└" <> base <> "┘"}
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

  def bell_curve_row(y_row, row_color, buckets) do
    row =
      buckets
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
      if slot_pos == ball_pos, do: IO.ANSI.bright <> IO.ANSI.yellow <> "☻" <> IO.ANSI.normal <> IO.ANSI.white, else: " "
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

  # defp blocks, do: 9601..9608 |> Enum.to_list |> to_string

  # defp pad(len), do: String.duplicate(" ", len)
  # defp pegs(num_pegs), do: String.duplicate(" .", num_pegs)
  # defp blank_row(len, row), do: pad(len) <> pegs(row)
  # defp blank_body(num_rows) do
  #   1..num_rows
  #   |> Enum.map_join("\n", &blank_row(num_rows - &1 + 1, &1))
  # end

  # # defp crosses(num_crosses), do: String.duplicate(" ┼", num_crosses)
  # defp heads(num_buckets), do: "├" <> crosses(num_buckets) <> " ┤"
  # # defp counters(counts), do: 
  # defp blank_buckets(num_buckets), do:

  #   heads(num_buckets) <> counters(num_buckets) <> bases(num_buckets)
  # end

  # def test do
  #   # rows = Fetch.dim(:rows)
  #   cols        = Fetch.dim(:cols)
  #   num_buckets = cols / 2 |> Float.ceil |> trunc
  #   num_rows    = num_buckets - 1
    
  #   body = num_rows |> blank_body
  #   buckets = num_buckets |> blank_buckets
  # end
end