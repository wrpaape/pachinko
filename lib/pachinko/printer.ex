defmodule Pachinko.Printer do
  @frame_interval 170 # capped at ~60 fps

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
      max_ball_spread
      |> generate_peg_rows

    initial_state = {peg_rows, server_pid}

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

  def print({live_balls, buckets}, {peg_rows, server_pid}) do
    # buckets
    # |> build_bell_curve
    # |> IO.puts

    peg_rows
    |> build_pachinko(live_balls)
    |> IO.puts
  end

  def print({_dead_balls, live_balls, buckets}, {peg_rows, server_pid}) do
    # IO.puts "dead"
      peg_rows
      |> Enum.split(live_balls |> length)
      |> Tuple.append(live_balls)
      |> build_pachinko
      |> IO.puts

    
    |> IO.puts

    # dead_rows =
    #   build_pachinko
    #   |> build
    # peg_rows
    # |> build_pachinko(live_balls)
    # |> List.concat()
  end

  def generate_peg_rows(last_num_pegs) do
    lpad_key = -(last_num_pegs + 1)
    lpad = &(String.duplicate(" ", last_num_pegs - &1))

    0..last_num_pegs
    |> Enum.map(fn(num_pegs) ->
      num_pegs
      |> Pachinko.generate_slots(" ")
      |> Map.put_new(lpad_key, lpad.(num_pegs))
    end)
  end

  defp map_rows(rows) do
    rows
    |> Enum.map_join("\n", &pachinko_row(&1))
  end

  def build_pachinko(live_rows, live_balls) do
    live_rows
    |> Enum.zip(live_balls)
    |> map_rows
  end

  def build_pachinko({live_rows, dead_rows, live_balls}) do
    build_pachinko(live_rows, live_balls) <> "\n" <> map_rows(dead_rows)
  end

  def build_bell_curve(buckets) do
    {:ok, rows} = :io.rows
    rows..1
    |> Enum.map_join("\n", &bell_curve_row(&1, buckets))
  end

  def bell_curve_row(row, buckets) do
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

  @doc """
  Receives ball_pos and splices a ball token (●)
  into a row of peg tokens (.) before dispatching
  the resulting display string to the print process.

  ## Example
      iex> import Pachinko.Printer, only: [pachinko_row: 2]
      ...> peg_row = Pachinko.generate_slots(2, " ")
      ...> pachinko_row(peg_row)
      " . . "

      ...> peg_row = Pachinko.generate_slots(5, " ")
      ...> pachinko_row({peg_row, 1})
      " . . . .●. . " 
  """
  defp sort_and_join(row) do
    row
    |> Enum.sort
    |> Enum.map_join(".", fn({_, token}) ->
      token
    end)
  end

  def pachinko_row({peg_row, ball_pos}) do
    peg_row
    |> Map.put(ball_pos, "●")

    |> Enum.reduce(fn(slot_pos, acc) ->
      case slot_pos do
        ^ball_pos -> " ●"
        _________ -> " ." 
      end
       <> <>
    end)

    |> sort_and_join
  end

  def pachinko_row(peg_row), do: sort_and_join(peg_row)

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