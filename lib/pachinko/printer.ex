defmodule Pachinko.Printer do
  @frame_interval 1_000 / 60

  use GenServer

  @moduledoc """
  Prints Pachinko state to stdio.
  """
#   """
#   ◬│●
#   ▁▂▃▄▅▆▇█
#            ●

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


  # External API

  def start_link(max_ball_spread, server_pid) do
    {:ok, _printer_pid} =
      __MODULE__
      |> GenServer.start_link([max_ball_spread, server_pid], name: __MODULE__)
    
    # {:ok, {:interval, _ref}} = 
      # @frame_interval
      # |> IO.inspect
      # |> :timer.apply_interval(GenServer, :cast, [__MODULE__, :print])
  end

  # GenServer implementation

  def init(max_ball_spread, server_pid) do
    peg_rows =
      max_ball_spread
      |> Pachinko.generate_slots(Tuple.duplicate(0, 3))

    initial_state = {peg_rows, server_pid}

    {:ok, initial_state}
  end

  def handle_cast(:print, {peg_rows, server_pid}) do
    IO.puts "LOL"
  end

  # helper functions

  defp generate_peg_rows(last_num_pegs) do
    0..last_num_pegs
    |> Enum.map(fn(num_pegs) ->
      num_pegs
      |> Pachinko.generate_slots(" ")
    end)
  end

  defp build_curve(buckets) do
    {:ok, rows} = :io.rows
    rows..1
    |> Enum.map_join("\n", &curve_row(&1, buckets))
  end

  defp curve_row(row, buckets) do
    buckets
    |> Enum.map_join(fn({_pos, {_count, full_blocks, remainder}}) ->
      cond do
        full_blocks < row -> " "
        full_blocks > row -> "█"
        remainder == 0    -> " "
        true              -> [9600 + remainder]
      end
    end)
  end

  defp splice_ball(peg_row, ball_pos) do
    peg_row
    |> Map.put(ball_pos, "●")
    |> Map.values
    |> Enum.join(".")
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