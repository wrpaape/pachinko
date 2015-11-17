defmodule Pachinko.Printer do
  # @frame_interval 17 # capped at ~60 fps
  @frame_interval 100

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

  def start_link(max_ball_spread, server_pid) do
    {:ok, _printer_pid} =
      __MODULE__
      |> GenServer.start_link([max_ball_spread, server_pid], name: __MODULE__)
  end

  def start do
    {:ok, {:interval, _ref}} = 
      @frame_interval
      |> :timer.apply_interval(GenServer, :cast, [__MODULE__, :print])
  end

  def state, do: GenServer.call(__MODULE__, :state)

  ########################################################################
  #                       GenServer implementation                       #
  ########################################################################

  def init([max_ball_spread, server_pid]) do
    peg_rows =
      max_ball_spread..0
      |> Enum.with_index
      |> Enum.map(&generate_peg_row/1)



    counters = 
      max_ball_spread
      |> generate_counters

    initial_state = {peg_rows, counters, server_pid}

    {:ok, initial_state}
  end

  def handle_cast(:print, state) do
    Pachinko.Server.update
    |> print(state)

    {:noreply, state}    
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  ######################################################################
  #                           public helpers                           #
  ######################################################################

  def print({balls, bucket_ball, buckets}, {peg_rows, counters, server_pid}) do
    printed_counters =
      counters
      |> print_counters(bucket_ball, buckets)

    printed_main = 
      peg_rows
      |> Enum.zip(balls)
      |> Enum.map_join("\n", &print_row(&1, buckets))

    printed_main <> "\n" <> printed_counters
    |> IO.puts 
  end

  def print_row({ { [pad | slots], y }, ball_pos }, buckets) do
    pad <> slot_row(slots, ball_pos, ".") <> pad <> bell_curve_row(y, buckets)
  end

  def generate_counters(num_counters) do
    tops = Pachinko.reflect_stagger(num_counters)
    base =
      "─"
      |> List.duplicate(num_counters)
      |> Enum.join("┴")

    {tops, "└" <> base <> "┘"}

# ├ ┼ ┼●┼ ┼ ┤  cols = 11 / 12
# │0│0│0│0│0│   
# └─┴─┴─┴─┴─┘
  end

  def generate_peg_row({pad_len, num_pegs}) do
    { [String.duplicate(" ", pad_len)  | Pachinko.reflect_stagger(num_pegs)], pad_len }
  end

  def bell_curve_row(y, buckets) do
    buckets
    |> Enum.map_join(fn({_pos, {_count, full_blocks, remainder}}) ->
      cond do
        full_blocks < y -> " "
        full_blocks > y -> "█"
        remainder  == 0 -> " "
        true            -> [9600 + remainder] |> List.to_string
      end
      |> String.duplicate(2)
    end)
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
      if slot_pos == ball_pos, do: "●", else: " "
    end)
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